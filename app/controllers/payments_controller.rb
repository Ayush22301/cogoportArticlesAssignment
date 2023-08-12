class PaymentsController < ApplicationController
    before_action :authenticate_user, only: [:subscribe,:payment_callback,:payments_page]
    require "razorpay"
    def subscribe
      subscription_plan = params[:subscription_plan]
      case subscription_plan
      when 'free'
        current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: Time.now + 1.month)
        render json: { message: 'Subscription successful', user: current_user }, status: :ok
      when '3_posts', '5_posts', '10_posts'
        case subscription_plan
        when '3_posts'
          amount = 3  # Amount in dollars
        when '5_posts'
          amount = 5  
        when '10_posts'
          amount = 10 
        end
  
        # Create a Razorpay order for the payment
        order = Razorpay::Order.create(amount: amount, currency: 'INR')
  
        # Store order details in the session for later verification
        session[:razorpay_order_id] = order.id
        session[:subscription_plan] = subscription_plan
        session[:payment_amount] = amount
  
        render json: { order_id: order.id, amount: amount }, status: :ok
      else
        render json: { error: 'Invalid subscription plan' }, status: :unprocessable_entity
      end
        rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
    

    def payment_callback
        # Verify the Razorpay signature to ensure the authenticity of the payment response
        razorpay_signature = params[:razorpay_signature]
        payment_id = params[:razorpay_payment_id]
        order_id = session[:razorpay_order_id]
        amount = params[:amount].to_i  
    
        # Construct the payload for signature verification
        payload = "#{order_id}|#{payment_id}"
    
        # Verify the signature using your Razorpay secret key
        client = Razorpay::Client.new(secret_key: 'HiHOYb5Xc3IWOoeg6lj8f7kZ')
        verified = client.utility.verify_payment_signature(payload, razorpay_signature)
    
        if verified && amount == params[:amount]
          # Update your database or grant access to the paid content
          # Update user's subscription based on the payment plan
          subscription_plan = session[:subscription_plan]
          case subscription_plan
          when '3_posts'
            current_user.update(subscription_plan: '3_posts', remaining_posts: 3, expires_at: Time.now + 1.month)
          when '5_posts'
            current_user.update(subscription_plan: '5_posts', remaining_posts: 5, expires_at: Time.now + 1.month)
          when '10_posts'
            current_user.update(subscription_plan: '10_posts', remaining_posts: 10, expires_at: Time.now + 1.month)
          end
    
          render json: { message: 'Payment confirmed and subscription updated' }, status: :ok
        else
          render json: { error: 'Payment verification failed' }, status: :unprocessable_entity
        end
      end

      def payments_page
        render 'payments'
      end


  end
  