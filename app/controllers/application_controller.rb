class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :safe_internal_path

  private

  # A user-supplied path is safe to link or redirect to only when it is a local
  # absolute path: a single leading slash followed by a non-slash, non-backslash
  # character. Blocks open redirects to "//host" and the "/\host" variant that
  # browsers normalise to a protocol-relative URL.
  def safe_internal_path(path, fallback)
    path.present? && path.match?(%r{\A/[^/\\]}) ? path : fallback
  end
end
