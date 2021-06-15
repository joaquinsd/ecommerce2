class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :payment_method

  def self.payment_method
   PaymentMethod.find_by(code: "PEC")
  end

  def self.start_payment_process(order, token)
    Payment.create(
      order_id: order.id,
      payment_method_id: payment_method.id,
      state: "processing",
      total: order.total,
      token: token
    )
  end

  def set_state_completed
    update_attributes(state: 'completed')
  end

  def complete_payment
    ActiveRecord::Base.transaction do
      order.set_state_completed
      set_state_completed
    end
  end
end
