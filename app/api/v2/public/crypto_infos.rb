# encoding: UTF-8
# frozen_string_literal: true
#
module API
    module V2
      module Public
        class CryptoInfos < Grape::API
          resource :cryptoinfos do
            desc 'Get all available crypto infos.',
                 is_array: true,
                 success: API::V2::Entities::CryptoInfo
            get "/" do
              present ::CryptoInfo.all, with: API::V2::Entities::CryptoInfo
            end
          end
        end
      end
    end
  end