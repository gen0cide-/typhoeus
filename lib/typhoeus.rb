require 'digest/sha2'
require 'ethon'

require 'typhoeus/config'
require 'typhoeus/easy_factory'
require 'typhoeus/errors'
require 'typhoeus/expectation'
require 'typhoeus/hydra'
require 'typhoeus/pool'
require 'typhoeus/request'
require 'typhoeus/response'
require 'typhoeus/version'

# If we are using any Rack-based application, then we need the Typhoeus rack
# middleware to ensure our app is running properly.
if defined?(Rack)
  require "rack/typhoeus"
end

# If we are using Rails, then we will include the Typhoeus railtie.
# if defined?(Rails)
#   require "typhoeus/railtie"
# end

# Typhoeus is a HTTP client library based on Ethon which
# wraps libcurl. Sitting on top of libcurl makes Typhoeus
# very reliable and fast.
#
# There are some gems using Typhoeus like
# {https://github.com/myronmarston/vcr VCR},
# {https://github.com/bblimke/webmock WebMock} or
# {https://github.com/technoweenie/faraday Faraday}. VCR
# and WebMock provide their own adapter whereas
# Faraday relies on {Faraday::Adapter::Typhoeus}
# since Typhoeus version 0.5.
#
# @example (see Typhoeus::Request)
# @example (see Typhoeus::Hydra)
#
# @see Typhoeus::Request
# @see Typhoeus::Hydra
# @see Faraday::Adapter::Typhoeus
#
# @since 0.5.0
module Typhoeus
  extend self
  extend Request::Actions
  extend Request::Callbacks::Types

  # The default Typhoeus user agent.
  USER_AGENT = "Typhoeus - https://github.com/typhoeus/typhoeus"

  USER_AGENTS = [
    "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; Crazy Browser 1.0.5)",
    "Mozilla/5.0 (X11; U; Linux amd64; en-US; rv:5.0) Gecko/20110619 Firefox/5.0",
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:2.0b8pre) Gecko/20101213 Firefox/4.0b8pre",
    "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)",
    "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 7.1; Trident/5.0)",
    "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0) chromeframe/10.0.648.205",
    "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727)",
    "Opera/9.80 (Windows NT 6.1; U; sv) Presto/2.7.62 Version/11.01",
    "Opera/9.80 (Windows NT 6.1; U; pl) Presto/2.7.62 Version/11.00",
    "Opera/9.80 (X11; Linux i686; U; pl) Presto/2.6.30 Version/10.61",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.861.0 Safari/535.2",
    "Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.872.0 Safari/535.2",
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.812.0 Safari/535.1",
  ]


  # Set the Typhoeus configuration options by passing a block.
  #
  # @example (see Typhoeus::Config)
  #
  # @yield [ Typhoeus::Config ]
  #
  # @return [ Typhoeus::Config ] The configuration.
  #
  # @see Typhoeus::Config
  def configure
    yield Config
  end

  # Stub out a specific request.
  #
  # @example (see Typhoeus::Expectation)
  #
  # @param [ String ] base_url The url to stub out.
  # @param [ Hash ] options The options to stub out.
  #
  # @return [ Typhoeus::Expectation ] The expecatation.
  #
  # @see Typhoeus::Expectation
  def stub(base_url, options = {}, &block)
    expectation = Expectation.all.find{ |e| e.base_url == base_url && e.options == options }
    if expectation.nil?
      expectation = Expectation.new(base_url, options)
      Expectation.all << expectation
    end

    expectation.and_return(&block) unless block.nil?
    expectation
  end

  # Add before callbacks.
  #
  # @example Add before callback.
  #   Typhoeus.before { |request| p request.base_url }
  #
  # @param [ Block ] block The callback.
  #
  # @yield [ Typhoeus::Request ]
  #
  # @return [ Array<Block> ] All before blocks.
  def before(&block)
    @before ||= []
    @before << block if block_given?
    @before
  end

  # Execute given block as if block connection is turned off.
  # The old block connection state is restored afterwards.
  #
  # @example Make a real request, no matter if it's blocked.
  #   Typhoeus::Config.block_connection = true
  #   Typhoeus.get("www.example.com").code
  #   #=> raise Typhoeus::Errors::NoStub
  #
  #   Typhoeus.with_connection do
  #     Typhoeus.get("www.example.com").code
  #     #=> :ok
  #   end
  #
  # @param [ Block ] block The block to execute.
  #
  # @return [ Object ] Returns the return value of the block.
  #
  # @see Typhoeus::Config#block_connection
  def with_connection
    old = Config.block_connection
    Config.block_connection = false
    result = yield if block_given?
    Config.block_connection = old
    result
  end
end
