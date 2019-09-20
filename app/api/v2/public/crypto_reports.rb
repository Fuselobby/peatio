# encoding: UTF-8
# frozen_string_literal: true
#
module API
    module V2
      module Public
        class CryptoReports < Grape::API
          resource :cryptoreports do
            desc 'Get all available crypto news reports.',
                 is_array: true,
                 success: API::V2::Entities::CryptoReport
            get "/" do
              present ::CryptoReport.all, with: API::V2::Entities::CryptoReport
            end
          end
        end
      end
    end
  end