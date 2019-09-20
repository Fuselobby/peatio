module SidekiqWorker
	class ArbitrageExecutorWorker
	  include Sidekiq::Worker
	  sidekiq_options retry: false
	  def perform()
	    puts "Performing arbitrage..."
	  end
	end
end