class Services < Ramaze::Controller
  map '/'
  
  def check name
    thing = Service[:name => name]
    thing.checked = true
    thing.save
    redirect_referrer    
  end
  
  def uncheck name
    thing = Service[:name => name]
    thing.checked = false
    thing.save
    redirect_referrer
  end    
  
  def create
    if request.post? and name = request[:name]
      name.strip!
      unless name.empty?       
        Service.create :name => name
      end
    end
    redirect  route('/')
  end
end
