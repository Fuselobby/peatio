# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class CryptoReport < Base
        expose(
            :id,
            documentation: {
                type: String,
                desc: "Unique report id."
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

        expose(
            :lang,
            documentation: {
                type: String,
                desc: 'Language string value.'
            }
        )
      end
    end
  end
end



