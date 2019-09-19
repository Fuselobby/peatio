# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class CryptoInfo < Base
        expose(
            :id,
            documentation: {
                type: String,
                desc: "Unique crypto id."
            }
        )

        expose(
            :crypto,
            documentation: {
                type: String,
                desc: 'Crypto Name.'
            }
        )

        expose(
            :context,
            documentation: {
                type: String,
                desc: 'json string value.'
            }
        )
      end
    end
  end
end


