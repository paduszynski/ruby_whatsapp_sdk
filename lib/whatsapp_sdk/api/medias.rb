# frozen_string_literal: true
# typed: strict

require "faraday"
require "faraday/multipart"

require_relative "request"
require_relative "response"
require_relative '../../../lib/whatsapp_sdk/api/responses/media_data_response'
require_relative '../../../lib/whatsapp_sdk/api/responses/success_response'

module WhatsappSdk
  module Api
    class Medias < Request
      class FileNotFoundError < StandardError
        extend T::Sig

        sig { returns(String) }
        attr_reader :file_path

        sig { params(file_path: String).void }
        def initialize(file_path)
          @file_path = file_path
          super("Couldn't find file_path: #{file_path}")
        end
      end

      # Get Media by ID.
      #
      # @param media_id [String] Media Id.
      # @return [WhatsappSdk::Api::Response] Response object.
      sig { params(media_id: String).returns(WhatsappSdk::Api::Response) }
      def media(media_id:)
        response = send_request(
          http_method: "get",
          endpoint: "/#{media_id}"
        )

        WhatsappSdk::Api::Response.new(
          response: response,
          data_class_type: WhatsappSdk::Api::Responses::MediaDataResponse
        )
      end

      # Download Media by URL.
      #
      # @param url URL.
      # @param file_path [String] The file_path to download the media e.g. "tmp/downloaded_image.png".
      # @return [WhatsappSdk::Api::Response] Response object.
      sig { params(url: String, file_path: String).returns(WhatsappSdk::Api::Response) }
      def download(url:, file_path:)
        response = download_file(url, file_path)

        response = if response.code.to_i == 200
                     { "success" => true }
                   else
                     { "error" => true, "status" => response.code }
                   end

        WhatsappSdk::Api::Response.new(
          response: response,
          data_class_type: WhatsappSdk::Api::Responses::SuccessResponse,
          error_class_type: WhatsappSdk::Api::Responses::ErrorResponse
        )
      end

      # Upload a media.
      # @param sender_id [Integer] Sender' phone number.
      # @param file_path [String] Path to the file stored in your local directory. For example: "tmp/whatsapp.png".
      # @param type [String] Media type e.g. text/plain, video/3gp, image/jpeg, image/png. For more information,
      # see the official documentation https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#supported-media-types.
      #
      # @return [WhatsappSdk::Api::Response] Response object.
      sig { params(sender_id: Integer, file_path: String, type: String).returns(WhatsappSdk::Api::Response) }
      def upload(sender_id:, file_path:, type:)
        raise FileNotFoundError, file_path unless File.file?(file_path)

        params = {
          messaging_product: "whatsapp",
          file: Faraday::FilePart.new(file_path, type),
          type: type
        }

        response = send_request(http_method: "post", endpoint: "#{sender_id}/media", params: params)

        WhatsappSdk::Api::Response.new(
          response: response,
          data_class_type: WhatsappSdk::Api::Responses::MediaDataResponse
        )
      end

      # Delete a Media by ID.
      #
      # @param media_id [String] Media Id.
      # @return [WhatsappSdk::Api::Response] Response object.
      sig { params(media_id: String).returns(WhatsappSdk::Api::Response) }
      def delete(media_id:)
        response = send_request(
          http_method: "delete",
          endpoint: "/#{media_id}"
        )

        WhatsappSdk::Api::Response.new(
          response: response,
          data_class_type: WhatsappSdk::Api::Responses::SuccessResponse
        )
      end
    end
  end
end
