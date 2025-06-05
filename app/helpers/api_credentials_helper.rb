module ApiCredentialsHelper
  # Masks an API key for display purposes, showing only the first 4 and last 4 characters
  def mask_api_key(api_key)
    return "•••••••••••••" unless api_key.present?

    if api_key.length > 8
      "#{api_key.first(4)}#{'•' * (api_key.length - 8)}#{api_key.last(4)}"
    else
      "•" * api_key.length  # If key is too short, just mask everything
    end
  end
end
