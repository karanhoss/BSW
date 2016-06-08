class HomeController < ApplicationController
  def home
  end

  def upload_receipts
  	csv_string = params[:datafile].read
  	receipts = ""
  	CSV2JSON.parse(csv_string, receipts)
  	prs = JSON.parse(receipts)

    springboard = Springboard::Client.new(
      'https://bsw-test.myspringboard.us/api',
      token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJmNTMwMmUxOS04YTdhLTQ0M2EtOTM5ZC1jMWMxYWI0NDc3Y2EiLCJpYXQiOjE0NjUxMjY0NTIsInN1YiI6MTAwMDE3LCJhdWQiOjIzODR9.y8VIMOKmVP0-GCYGe1KbSSz2dEQG_79e8wTpa3sa-3g')

    new_receipt = springboard["purchasing/receipts"]
    response = new_receipt.post! :order_id => prs[0]["order_id"]
    #puts response.headers['Location']
    line_url = response.headers['Location'][4..-1] + "/lines"
    receipt_id = response.headers['Location'][25..-1]
    receipt_line = springboard[line_url]

    for pr in prs 
      upc = pr["item_lookup"].to_s
      order_id = pr["order_id"]
      qty = pr["qty"]
      item_id = nil

      order_line_url = "purchasing/orders/" + order_id.to_s + "/lines"
      get_order = springboard[order_line_url]
      response = get_order.get.body[:results]
      for order_line in response
        if order_line[:item_custom][:upc] === upc
          item_id = order_line[:item_id]
          break
        end
      end

      unless item_id == nil
        response = receipt_line.post! :item_id => item_id, :qty => qty, :receipt_id => receipt_id
      end
    end

  	render template: 'home/success'
  end
end
