default_platform(:ios)

platform :ios do
  desc "Build & upload to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "PrintMyRide")
    upload_to_testflight(skip_waiting_for_build_processing: false, distribute_external: false)
  end
end