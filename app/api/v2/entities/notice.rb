# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class Notice < Base
        expose(
            :id,
            documentation: {
                type: String,
                desc: "Unique notfication id."
            }
        )

        expose(
            :notice_title,
            documentation: {
                type: String,
                desc: 'Notice Title.'
            }
        )

        expose(
            :description,
            documentation: {
                type: String,
                desc: 'description.'
            }
        )

        expose(
            :from_date,
            format_with: :iso8601,
            documentation: {
                type: String,
                desc: 'The datetime when notice starts'
            }
        )

        expose(
            :to_date,
            format_with: :iso8601,
            documentation: {
                type: String,
                desc: 'The datetime when notice ends'
            }
        )

        expose(
            :created_at,
            format_with: :iso8601,
            documentation: {
                type: String,
                desc: 'Trade create time in iso8601 format.'
            }
        )
      end
    end
  end
end

