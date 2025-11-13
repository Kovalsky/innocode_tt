require 'rails_helper'

RSpec.describe GoogleDistanceService do
  let(:route) { create(:route) }
  let(:service) { described_class.new(route: route) }
  let(:redis_store) { instance_double('RedisStore') }
  let(:response_body) do
    {
      routes: [
        {
          duration: '100s',
          staticDuration: '50s',
          distanceMeters: 1000,
        }
      ]
    }
  end
  let(:response_status) { 200 }

  before do
    allow(Rails.logger).to receive(:error)
    allow(redis_store).to receive(:set)
    stub_const('REDIS_STORE', redis_store)
    stub_request(:post, GoogleDistanceService::GOOGLE_MAPS_API_URL)
      .to_return(
        status: response_status,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe "#call" do

    context "when the API request is successful" do
      context "when routes are found and fields can be calculated" do
        it "updates route's last_updated_at" do
          expect { service.call }.to change { route.reload.last_updated_at }
        end

        it "saves result to redis" do
          cache_obj = {
            updated_at: Time.current.to_i,
            duration: 100,
            static_duration: 50,
            distance: 1000,
            speed: 36,
            traffic_state: 'normal'
          }.to_json

          expect(redis_store).to receive(:set).with("GoogleDistanceService:#{route.id}", cache_obj, expires_in: 5.minutes)
          service.call
        end
      end

      context "when routes are not found" do
        let(:response_body) { {routes: []} }
        it "logs error" do
          expect(Rails.logger).to receive(:error).with("No routes found between the specified origin and destination")
          expect { service.call }.not_to change { route.reload.last_updated_at }
        end
      end

      context "when fields cannot be calculated" do
        let(:response_body) { {routes: [{duration: '120s'}]} }
        it "logs error" do
          expect(Rails.logger).to receive(:error)
            .with("Requested fields cant be calculated by Google service and were omitted in response.")
          expect { service.call }.not_to change { route.reload.last_updated_at }
        end
      end
    end

    context "when the API request fails" do
      context "when a client error occurs" do
        let(:response_status) { 400 }
        let(:response_body) { 'Bad Request' }

        it "logs error" do
          expect(Rails.logger).to receive(:error)
            .with("Client error from Google Maps API: #{response_status} - #{response_body}")
          expect { service.call }.not_to change { route.reload.last_updated_at }
        end
      end
      context "when a server error occurs" do
        let(:response_status) { 500 }
        let(:response_body) { 'Internal Server Error' }

        it "logs error" do
          expect(Rails.logger).to receive(:error)
            .with("Server error from Google Maps API: #{response_status} - #{response_body}")
          expect { service.call }.not_to change { route.reload.last_updated_at }
        end
      end
    end
  end

end
