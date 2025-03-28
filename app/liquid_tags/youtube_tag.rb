class YoutubeTag < LiquidTagBase
  PARTIAL = "liquids/youtube".freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @input = CGI.unescape_html(strip_tags(input.strip))
    @id = extract_video_id || raise(StandardError, "Invalid YouTube ID or URL")
    @width = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { id: @id, width: @width, height: @height }
    )
  end

  private

  def extract_video_id
    input = @input.to_s.strip
    video_id = nil
    seconds = 0
  
    # Extract video ID from various URL formats
    case input
    when %r{youtu\.be/([^?&#/]+)}
      video_id = $1
    when %r{youtube\.com/watch.*[?&]v=([^&#]+)}
      video_id = $1
    when %r{youtube\.com/embed/([^?&#/]+)}
      video_id = $1
    when %r{youtube\.com/shorts/([^?&#/]+)}
      video_id = $1
    when %r{youtube\.com/live/([^?&#/]+)}
      video_id = $1
    else
      video_id = input.split(/[?#&]/, 2).first
    end
  
    # Handle time parameters from both ?t= and #t= formats
    if input =~ /[?&#]t=([0-9hms]+)/
      time_str = $1
      seconds = parse_time_string(time_str)
    end
  
    unless video_id && video_id.match?(/\A[a-zA-Z0-9_-]{11}\z/)
      raise StandardError, "Invalid YouTube ID or URL"
    end
  
    seconds.positive? ? "#{video_id}?start=#{seconds}" : video_id
  end

  def parse_time_string(time_str)
    if time_str =~ /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$/
      hours   = $1 ? $1.to_i : 0
      minutes = $2 ? $2.to_i : 0
      secs    = $3 ? $3.to_i : 0
      hours * 3600 + minutes * 60 + secs
    else
      time_str.to_i
    end
  end
end

Liquid::Template.register_tag("youtube", YoutubeTag)
YOUTUBE_REGEX = %r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/|live/))}i
UnifiedEmbed.register(YoutubeTag, regexp: YOUTUBE_REGEX)