class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: %i[pay_with_paypal]

  def update
    product = params[:cart][:product_id]
    quantity = params[:cart][:quantity]

    current_order.add_product(product, quantity)

    redirect_to root_url, notice: "Product added successfuly"
  end

  def show
    @order = current_order
  end

  def pay_with_paypal
    response = EXPRESS_GATEWAY.setup_purchase(@order.total_in_cents,
      ip: request.remote_ip,
      return_url: process_paypal_payment_cart_url,
      cancel_return_url: root_url,
      allow_guest_checkout: true,
      currency: "USD"
    )
    token = response.token
    Payment.start_payment_process(@order, token)
    redirect_to EXPRESS_GATEWAY.redirect_url_for(token)
  end

  def process_paypal_payment
    @details = EXPRESS_GATEWAY.details_for(params_token)
    response = EXPRESS_GATEWAY.purchase(order_total, express_purchase_options)
    if response.success?
      payment = Payment.find_by(token: response.token)
      payment.complete_payment
    end
  end

  private
  def set_order
    @order = Order.find(params[:cart][:order_id])
  end

  def params_token
    params[:token]
  end

  def order_total
    @details.params['order_total'].to_d * 100
  end

  def express_purchase_options
    {
      ip: request.remote_ip,
      token: params_token,
      payer_id: details.payer_id,
      currency: 'USD'
    }
  end
end
