class RevisionsController < ApplicationController
    def revision_history
        results = Revision.where(article_id: params[:id])
        response = results.map do |result|
            {
                article_id: result.article_id,
                title: result.title,
                content: result.content,
                revision_time: result.revision_time
            }
        end
        render json: response
    end
end