require "conektapayments/version"

module Conektapayments
  class Payments
	attr_accessor :amount, :description, :reservation_code, :conekta_id, :email, :card_owner, :item_description, :type, :total_to_pay

	def initialize(payment_hash)

	  service_charge = GlobalConstants::SERVICE_CHARGE

	  @amount 		= payment_hash["amount"]
	  @description 		= payment_hash["description"]
	  @reservation_code 	= payment_hash["reservation_code"]
	  @conekta_id 		= payment_hash["conekta_id"]
	  @email 		= payment_hash["email"]
	  @card_owner 		= payment_hash["card_owner"]
	  @total_to_pay		= ((payment_hash["amount"].to_i + service_charge) * 100)
	  @item_description 	= payment_hash["item_description"]
	  @type			= payment_hash["type"]
	end

	def applyCharge
	  message= ""
	  status = false

	  begin

		@charge = Conekta::Charge.create({
        	  amount: self.total_to_pay,
        	  currency: "MXN",
        	  description: self.description,
        	  reference_id: self.reservation_code,
        	  card: self.conekta_id,
        	  details: {
          	    email: self.email,
          	    line_items: [{
              	      "name" => self.type,
              	      "description" => self.item_description,
              	      "unit_price" => self.total_to_pay,
                      "quantity" => 1,
                      "type" => self.type
          	    }]
        	  }
      		})	    

	        conekta_message = @charge.status
      		conekta_id       = @charge.id

		status = true
	        message= @charge.status

	  rescue Conekta::ParameterValidationError, Conekta::ProcessingError, Conekta::Error, Exception => e
		puts e.message_to_purchaser
      		conekta_message     = e.message_to_purchaser
	  	message		    = e.message_to_purchaser
	  ensure
		reservation 			 = Reservation.find_by_code(self.reservation_code)
	        flight_payment                   = FlightPayment.new
	        flight_payment.reservation_id    = reservation.id
	        flight_payment.conekta_response  = conekta_message
	        flight_payment.conekta_id        = conekta_id
	        flight_payment.save!		
	  end
	  return ConektaResponse.new(status, message)	
	end
  end
end
