class ArticlesController < ApplicationController
  before_action :authenticate_user, only: [:create,:update,:delete]

    def filter
      author_name = params.fetch(:author, "")
      title = params.fetch(:title, "")
      min_likes = params.fetch(:min_likes, nil) 
      max_likes = params.fetch(:max_likes, nil) 
      min_comments = params.fetch(:min_comments, nil) 
      max_comments = params.fetch(:max_comments, nil) 
      start_date = params.fetch(:start_date, nil)
      end_date = params.fetch(:end_date, nil)
    
      articles = Article.all

      if start_date.present? && end_date.present?
        start_date = DateTime.parse(start_date)
        end_date = DateTime.parse(end_date).end_of_day
        articles = articles.where(created_at: start_date..end_date)
      elsif start_date.present?
        start_date = DateTime.parse(start_date)
        articles = articles.where("created_at >= ?", start_date)
      elsif end_date.present?
        end_date = DateTime.parse(end_date).end_of_day
        articles = articles.where("created_at <= ?", end_date)
      end
    
      if author_name.present?
        # Find the author by name (case-insensitive search)
        author = Author.find_by("lower(name) = ?", author_name.downcase)
    
        # If the author exists, filter articles by the author's ID
        articles = articles.where(author: author) if author
      end
    
      if title.present?
        articles = articles.where(title: title)
      end
    
      if min_likes.present? && max_likes.present?
        articles = articles.where(no_of_likes: min_likes..max_likes)
      elsif min_likes.present?
        articles = articles.where("no_of_likes >= ?", min_likes)
      elsif max_likes.present?
        articles = articles.where("no_of_likes <= ?", max_likes)
      end
    
      if min_comments.present? && max_comments.present?
        articles = articles.where("no_of_comments >= ? AND no_of_comments <= ?", min_comments, max_comments)
      elsif min_comments.present?
        articles = articles.where("no_of_comments >= ?", min_comments)
      elsif max_comments.present?
        articles = articles.where("no_of_comments <= ?", max_comments)
      end
      
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author.name, 
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          read_time: article.read_time
        }
      end
    
      render json: response
    end
    

    def search
      title = article_search_params[:title].presence
      description = article_search_params[:description].presence
      genre = article_search_params[:genre].presence
      author_name = article_search_params[:author].presence
    
      articles = Article.all
    
      articles = articles.where("lower(title) LIKE ?", "%#{title.downcase}%") if title
      articles = articles.where("lower(description) LIKE ?", "%#{description.downcase}%") if description
      articles = articles.where("lower(genre) LIKE ?", "%#{genre.downcase}%") if genre
    
      if author_name.present?
        authors = Author.where("name ILIKE ?", "%#{author_name}%")
        author_ids = authors.pluck(:id)
        articles = articles.where(author_id: author_ids) if author_ids.any?
      end
      
    
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author.name, 
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          read_time: article.read_time
        }
      end
    
      render json: response
    end
    
    
    

    def sort
      sort_by = params.fetch(:sort_by, 'likes') 
      ordr = params.fetch(:order, :desc) # Default to descending order
    
      valid_sort_columns = ['likes', 'comments']
      sort_by = valid_sort_columns.include?(sort_by) ? sort_by : 'likes'

      if sort_by == 'likes'
        sort_by = 'no_of_likes'
      else
        sort_by = 'no_of_comments'
      end

    
      articles = Article.order("#{sort_by} #{ordr}")
    
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          read_time: article.read_time
        }
      end
    
      render json: response
    end
    

    def create
         # Permit only the specific fields from the request parameters
        permitted_params = article_params

        author = Author.find_by(id: current_user.author_id)

        des = permitted_params[:description]

        wordsCount = des.split(/\s+/).length     #this gives no. of words in the 'description'

        rtime = wordsCount/200.0         #200 is the avg no. of words I have assumed that can be read in a minute 
        #rt time is float value with unit minute

        article = Article.new(
            title: permitted_params[:title],
            description: permitted_params[:description],
            genre: permitted_params[:genre],
            author: author,
            no_of_likes: 0,
            no_of_comments: 0,
            likes: [],
            comments: [],
            read_time: rtime,
            isDraft: permitted_params[:isDraft]
        )

        # Attach the 'image' file to the article if present
        article.image.attach(permitted_params[:image]) if permitted_params[:image].present?

        if article.save
            author.update(article_ids: author.article_ids << article.id)

            response = {
            id: article.id,
            title: article.title,
            author: article.author,
            description: article.description,
            genre: article.genre,
            image_url: article.image.attached? ? url_for(article.image) : nil,
            created_at: article.created_at,
            updated_at: article.updated_at,
            no_of_likes: article.no_of_likes,
            no_of_comments: article.no_of_comments,
            likes: article.likes,
            comments: article.comments,
            read_time: article.read_time,
            isDraft: article.isDraft
            }

            render json: response, status: :created
        else
            render json: { error: 'Failed to create the article' }, status: :unprocessable_entity
        end
    end

    def update
        article = Article.find_by(id: params[:id])

        if article.author.id != current_user.author_id
          render json: {error: "This article doesn't belongs to the current user"}, status: :not_found
          return
        end
    
        unless article
          render json: { error: 'Article not found' }, status: :not_found
          return
        end
    
        # Permit only the specific fields from the request parameters
        permitted_params = article_params.except(:author)

        if permitted_params[:description]
          des = permitted_params[:description]

          wordsCount = des.split(/\s+/).length

          rtime = wordsCount/200.0

          permitted_params[:read_time] = rtime
        end

        # Update the article with the permitted parameters
        if article.update(permitted_params)
            # Build a JSON response with the updated article details
            response = {
            id: article.id,
            title: article.title,
            author: article.author.name,
            description: article.description,
            genre: article.genre,
            image_url: article.image.attached? ? url_for(article.image) : nil,
            created_at: article.created_at,
            updated_at: article.updated_at,
            no_of_likes: article.no_of_likes,
            no_of_comments: article.no_of_comments,
            likes: article.likes,
            comments: article.comments,
            read_time: article.read_time,
            isDraft: article.isDraft,
            views: article.views
            }

            revision = Revision.new(
              article_id: article.id,
              title: article.title,
              content: article.description,
              revision_time: Time.now
            )

            revision.save

            render json: response
        else
            render json: { error: 'Failed to update the article' }, status: :unprocessable_entity
        end
    end   


    def delete
        article = Article.find_by(id: params[:id])

        if article.author.id != current_user.author_id
          render json: {error: "This article doesn't belongs to the current user"}, status: :not_found
          return
        end

        if article
          # Get the associated author of the article
          author = article.author
      
          # Destroy the associated image along with the article
          article.image.purge if article.image.attached?
      
          # Destroy the article
          article.destroy
      
          # Remove the article's ID from the author's article_ids array
          author.update(article_ids: author.article_ids - [params[:id].to_i])
      
          render json: { message: 'Article deleted successfully!' }, status: :ok
        else
          render json: { error: 'Article not found' }, status: :not_found
        end
    end

    def all
      articles = Article.includes(image_attachment: :blob)
      response = articles.map do |article|
          {
            id: article.id,
            title: article.title,
            author: article.author,
            description: article.description,
            genre: article.genre,
            image_url: article.image.attached? ? url_for(article.image) : nil,
            created_at: article.created_at,
            updated_at: article.updated_at,
            no_of_likes: article.no_of_likes,
            no_of_comments: article.no_of_comments,
            likes: article.likes,
            comments: article.comments,
            read_time: article.read_time
          }
      end
      render json: response
    end

    
    def home
      bpp = params.fetch(:books_per_page, 3).to_i
      offset = [params.fetch(:page, 1).to_i, 1].max
      max_len = Article.all.count
      bpp = [bpp, max_len].min
      o_max = (max_len / bpp.to_f).ceil
      offset = [offset, o_max].min
      articles = Article.includes(image_attachment: :blob).offset((offset-1)*bpp).limit(bpp)
      response = articles.map do |article|
          {
            id: article.id,
            title: article.title,
            author: article.author,
            description: article.description,
            genre: article.genre,
            image_url: article.image.attached? ? url_for(article.image) : nil,
            created_at: article.created_at,
            updated_at: article.updated_at,
            no_of_likes: article.no_of_likes,
            no_of_comments: article.no_of_comments,
            likes: article.likes,
            comments: article.comments,
            read_time: article.read_time
          }
      end
      render json: response
  end
    # def reset_remaining_posts
    #   current_user.update(remaining_posts: current_user.subscription_plan.to_i)
    #   render json: { message: 'Remaining posts reset' }, status: :ok
    # end

    def top_posts
      all_articles = Article.all
    
      top_articles = all_articles.sort do |a, b|
        views_comparison = b.views <=> a.views
        likes_comparison = b.no_of_likes <=> a.no_of_likes
        comments_comparison = b.no_of_comments <=> a.no_of_comments
    
        if views_comparison.zero?
          if likes_comparison.zero?
            comments_comparison
          else
            likes_comparison
          end
        else
          views_comparison
        end
      end
    
    #   render json: top_articles, status: :ok
    # end
    


      response = top_articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          read_time: article.read_time,
          views: article.views
        }
    end
    render json: response
    end


    

    private

    def article_params
        # Permit only the specific fields from the request parameters
        params.permit(:title, :description, :genre, :image, :isDraft)
    end

    def article_search_params
        params.permit(:title, :author, :description, :genre)
    end
end
