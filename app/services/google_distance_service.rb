# Service to fetch route distance and duration from Google Maps Directions API
# Saves the result in Redis and updates the route's last_updated_at field

class GoogleDistanceService < BaseService
  GOOGLE_MAPS_API_URL = 'https://routes.googleapis.com/directions/v2:computeRoutes'.freeze
  ROUTE_FIELDS = %w(duration distanceMeters staticDuration).freeze

  def initialize(route:)
    @route = route
    @conn = Faraday.new(
      url: GOOGLE_MAPS_API_URL,
      headers: {'Content-Type' => 'application/json', 'X-Goog-Api-Key' => ENV['GOOGLE_MAPS_API_KEY']}
    )
  end

  def call
    response = make_api_request
    parsed_body = JSON.parse(response.body)

    case response.status
      when 200
        handle_api_response(parsed_body)
      when 400..499
        Rails.logger.error("Client error from Google Maps API: #{response.status} - #{parsed_body}")
      when 500..599
        Rails.logger.error("Server error from Google Maps API: #{response.status} - #{parsed_body}")
    end
  end

  private

  def make_api_request
    @conn.post do |req|
      req.headers['X-Goog-FieldMask'] = "routes.#{ROUTE_FIELDS.join(',routes.')}"
      req.body = api_request_body
    end
  end

  def handle_api_response(response)
    return unless route_found?(response)
    return unless required_fields_present?(response)

    save_route_data(response)
  end


  def route_found?(response)
    return true if response['routes'].present?

    Rails.logger.error("No routes found between the specified origin and destination")
  end

  def required_fields_present?(responce)
    return true if responce['routes'].first['duration'].present? && responce['routes'].first['distanceMeters'].present?

    Rails.logger.error("Requested fields cant be calculated by Google service and were omitted in response.")
  end

  def save_route_data(responce)
    route = responce['routes'].first

    cache_key = "GoogleDistanceService:#{@route.id}"
    cache_json = {
      updated_at: Time.current.to_i,
      duration: route['duration'].chop.to_i, # in seconds
      static_duration: route['staticDuration'].chop.to_i, # in seconds
      distance: route['distanceMeters'], # in meters
      speed: speed_kmh(route),
      traffic_state: determine_traffic_state(route)
    }.to_json

    REDIS_STORE.set(cache_key, cache_json, expires_in: 5.minutes)
    @route.update(last_updated_at: Time.current)
  end

  def determine_traffic_state(route)
    return 'jam' if speed_kmh(route) <= 10
    return 'normal' if speed_kmh(route) <= 40

    'freeway'
  end
  
  def speed_kmh(route)
    (route['distanceMeters'] / route['duration'].chop.to_i * 3.6).to_i
  end

  def api_request_body
    {
      origin: {
        location: {
          latLng: {
            latitude: @route.origin_lat,
            longitude: @route.origin_lon
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: @route.destination_lat,
            longitude: @route.destination_lon
          }
        }
      }
    }.to_json
  end
end
