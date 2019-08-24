# encoding: UTF-8
# frozen_string_literal: true
#
module API
  module V2
    module Public
      class Notices < Grape::API

        resource :notices do
          desc 'Get all available notices.',
               is_array: true,
               success: API::V2::Entities::Notice
          get "/" do
            present ::Notice.enabled.ordered, with: API::V2::Entities::Notice
          end
        end
      end
    end
  end
end