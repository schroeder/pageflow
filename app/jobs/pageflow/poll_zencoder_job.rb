module Pageflow
  class PollZencoderJob
    @queue = :resizing

    extend StateMachineJob

    def self.perform_with_result(file, options, api = ZencoderApi.instance)
      result = catch(:halt) do
        poll_zencoder(file, api)
        fetch_input_details(file, api)
        fetch_thumbnail(file)
        :ok
      end
    ensure
      file.save!
    end

    private

    def self.poll_zencoder(file, api)
      info = api.get_info(file.job_id)

      file.encoding_progress = info[:finished] ? 100 : info[:progress];
      file.encoding_error_message = nil

      if info[:state] === 'failed'
        throw(:halt, :error)
      elsif !info[:finished]
        throw(:halt, :pending)
      end
    rescue ZencoderApi::RecoverableError => e
      file.encoding_error_message = e.message
      throw(:halt, :pending)
    rescue ZencoderApi::Error => e
      file.encoding_error_message = e.message
      raise
    end

    def self.fetch_thumbnail(file)
      return unless file.respond_to?(:thumbnail)
      file.thumbnail = URI.parse(file.zencoder_thumbnail.url)
      file.poster = URI.parse(file.zencoder_poster.url)
    rescue OpenURI::HTTPError
      throw(:halt, :pending)
    end

    def self.fetch_input_details(file, api)
      file.meta_data_attributes = api.get_input_details(file.job_id)
    rescue ZencoderApi::RecoverableError => e
      file.encoding_error_message = e.message
      throw(:halt, :pending)
    rescue ZencoderApi::Error => e
      file.encoding_error_message = e.message
      raise
    end
  end
end
