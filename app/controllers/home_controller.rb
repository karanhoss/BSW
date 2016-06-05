class HomeController < ApplicationController
  def home
  end

  def upload_receipts
  	csv_string = params[:datafile].read
  	receipts = ""
	CSV2JSON.parse(csv_string, receipts)
	receipts = JSON.parse(receipts)
	debugger
	springboard = Springboard::Client.new(
	  'https://bsw-test.myspringboard.us/api',
	  token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJmNTMwMmUxOS04YTdhLTQ0M2EtOTM5ZC1jMWMxYWI0NDc3Y2EiLCJpYXQiOjE0NjUxMjY0NTIsInN1YiI6MTAwMDE3LCJhdWQiOjIzODR9.y8VIMOKmVP0-GCYGe1KbSSz2dEQG_79e8wTpa3sa-3g')
	receipt_s = springboard["purchasing/receipts"]
	for receipt in receipts
	  order_id = receipt[:order_id]
	  new_receipt = receipt_s.post! :order_id => order_id
	  line_url = new_receipt.headers['Location'][4..-1] + "/lines"
	  line_s = springboard[line_url]

	  lines = receipt[:lines]
	  if lines.present?
	  	for line in lines 
		    item_id = line[:item_id]
		    qty = line[:qty]
		    receipt_id = new_receipt.headers['Location'][25..-1]
		    new_line = line_s.post! :item_id => item_id, :qty => qty, :receipt_id => receipt_id
		end
	  end
	end

  	render template: 'home/success'
  end
end
