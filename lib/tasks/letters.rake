namespace :letters do
  desc "Bulk regenerate and resend visa letter PDFs to participants whose letter was already sent for an event (default: Fallout)"
  task :bulk_regenerate, [ :event_name ] => :environment do |_t, args|
    event_name = args[:event_name].presence || "Fallout"

    events = Event.where(name: event_name).to_a
    abort "No event found with name #{event_name.inspect}" if events.empty?

    if events.size > 1
      puts "Warning: #{events.size} events match name #{event_name.inspect} (ids: #{events.map(&:id).join(', ')}). Processing all of them."
    end

    total = 0
    events.each do |event|
      applications = event.visa_letter_applications.letter_sent
      count = applications.count
      puts "Event #{event.name.inspect} (#{event.slug}): #{count} application(s) with letter already sent"

      applications.find_each.with_index do |application, index|
        RegenerateAndSendLetterJob.perform_later(application.id)
        total += 1
        puts "  Enqueued #{index + 1}/#{count}: #{application.reference_number} -> #{application.participant.email}"
      end
    end

    puts "Done! Enqueued #{total} regenerate-and-send job(s)."
  end
end
