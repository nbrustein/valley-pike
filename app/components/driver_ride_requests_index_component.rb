class DriverRideRequestsIndexComponent < ViewComponent::Base
  include Memery

  def initialize(ride_requests:, current_user:)
    @ride_requests = ride_requests
    @current_user = current_user
  end

  memoize def your_upcoming_rides
    @ride_requests.select {|rr|
      assigned?(rr) && !rr.completed? && !rr.cancelled? && rr.date >= Date.current
    }
  end

  memoize def looking_for_drivers
    @ride_requests.select {|rr|
      !assigned?(rr) && !rr.has_enough_drivers? && !rr.completed? && !rr.cancelled? && rr.date >= Date.current
    }
  end

  memoize def no_longer_available
    @ride_requests.select {|rr|
      !assigned?(rr) && rr.date >= Date.current &&
        (rr.has_enough_drivers? || rr.cancelled?) && !rr.completed?
    }
  end

  memoize def your_completed_rides
    @ride_requests.select {|rr|
      assigned?(rr) && (rr.completed? || rr.cancelled?)
    }
  end

  def render_looking_for_drivers_section
    if looking_for_drivers.any?
      return render_section("Looking for Drivers", looking_for_drivers, icon: "fa-user-plus")
    end

    message = if no_longer_available.any? {|rr| !rr.cancelled? }
      "All upcoming rides have drivers assigned."
    else
      "There are no upcoming rides."
    end

    tag.div(class: "space-y-3") do
      safe_join([
        section_header("Looking for Drivers", "fa-user-plus"),
        tag.p(message, class: "text-secondary"),
      ])
    end
  end

  def render_section(title, rides, icon: nil)
    return if rides.empty?

    tag.div(class: "space-y-3") do
      safe_join([
        section_header(title, icon),
        *rides.map {|rr| render_ride_card(rr) },
      ])
    end
  end

  def section_header(title, icon)
    tag.h2(class: "text-sm font-semibold uppercase tracking-wide text-secondary") do
      safe_join([
        icon ? tag.i(class: "fa-solid #{icon} mr-1.5") : nil,
        title,
      ].compact)
    end
  end

  RIDE_CARD_CLASS = "block rounded-2xl border border-primary/10 bg-white/80 p-4 shadow-sm " \
    "backdrop-blur transition hover:shadow-md sm:p-6"

  def render_ride_card(ride_request)
    link_to(helpers.driver_ride_request_path(id: ride_request.id), class: RIDE_CARD_CLASS) do
      tag.div(class: "flex items-start justify-between gap-4") do
        safe_join([
          tag.div(class: "min-w-0 flex-1") do
            safe_join([
              tag.h3(ride_request.short_description, class: "text-lg font-semibold text-primary"),
              tag.p(ride_request.organization.name, class: "mt-1 text-sm text-secondary"),
              if ride_request.destination_address.present?
                tag.p(class: "mt-1 text-sm text-secondary") do
                  "#{ride_request.destination_address.name}, #{ride_request.destination_address.city}"
                end
              end,
            ].compact)
          end,
          tag.div(class: "shrink-0 text-right") do
            tag.p(ride_request.date.strftime("%b %-d, %Y"), class: "text-sm font-medium text-primary")
          end,
        ])
      end
    end
  end

  private

  def assigned?(ride_request)
    ride_request.driver_assignments.any? {|da| da.driver_id == @current_user.id }
  end
end
