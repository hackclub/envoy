# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_03_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.uuid "admin_id"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "trackable_id", null: false
    t.string "trackable_type", null: false
    t.string "user_agent"
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["admin_id"], name: "index_activity_logs_on_admin_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["trackable_type", "trackable_id"], name: "index_activity_logs_on_trackable_type_and_trackable_id"
  end

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.boolean "notify_new_applications", default: true, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "super_admin", default: false, null: false
    t.string "uid"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["provider", "uid"], name: "index_admins_on_provider_and_uid", unique: true
    t.index ["remember_token"], name: "index_admins_on_remember_token", unique: true
    t.index ["unlock_token"], name: "index_admins_on_unlock_token", unique: true
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "admin_id", null: false
    t.datetime "application_deadline"
    t.boolean "applications_open", default: true, null: false
    t.string "city", null: false
    t.string "contact_email", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date", null: false
    t.string "name", null: false
    t.jsonb "rejection_reason_templates", default: [], null: false
    t.string "slug", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.string "venue_address", null: false
    t.string "venue_name", null: false
    t.index ["active"], name: "index_events_on_active"
    t.index ["admin_id"], name: "index_events_on_admin_id"
    t.index ["applications_open"], name: "index_events_on_applications_open"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["start_date"], name: "index_events_on_start_date"
  end

  create_table "letter_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.uuid "event_id"
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.string "signatory_name", null: false
    t.string "signatory_title", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "active"], name: "index_letter_templates_on_event_id_and_active"
    t.index ["event_id"], name: "index_letter_templates_on_event_id"
    t.index ["is_default"], name: "index_letter_templates_on_is_default"
  end

  create_table "participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "country_of_birth", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.datetime "email_verified_at"
    t.string "full_name", null: false
    t.text "full_street_address", null: false
    t.string "phone_number", null: false
    t.string "place_of_birth"
    t.datetime "updated_at", null: false
    t.integer "verification_attempts", default: 0, null: false
    t.string "verification_code"
    t.datetime "verification_code_sent_at"
    t.index ["email"], name: "index_participants_on_email"
    t.index ["verification_code"], name: "index_participants_on_verification_code"
  end

  create_table "visa_letter_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.datetime "letter_generated_at"
    t.datetime "letter_sent_at"
    t.uuid "participant_id", null: false
    t.string "reference_number", null: false
    t.text "rejection_reason"
    t.string "rejection_type"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.string "status", default: "pending_verification", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.string "verification_code"
    t.index ["event_id"], name: "index_visa_letter_applications_on_event_id"
    t.index ["participant_id", "event_id"], name: "index_visa_letter_applications_on_participant_id_and_event_id", unique: true
    t.index ["participant_id"], name: "index_visa_letter_applications_on_participant_id"
    t.index ["reference_number"], name: "index_visa_letter_applications_on_reference_number", unique: true
    t.index ["rejection_type"], name: "index_visa_letter_applications_on_rejection_type"
    t.index ["reviewed_by_id"], name: "index_visa_letter_applications_on_reviewed_by_id"
    t.index ["status"], name: "index_visa_letter_applications_on_status"
    t.index ["submitted_at"], name: "index_visa_letter_applications_on_submitted_at"
    t.index ["verification_code"], name: "index_visa_letter_applications_on_verification_code", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "admins"
  add_foreign_key "events", "admins"
  add_foreign_key "letter_templates", "events"
  add_foreign_key "visa_letter_applications", "admins", column: "reviewed_by_id"
  add_foreign_key "visa_letter_applications", "events"
  add_foreign_key "visa_letter_applications", "participants"
end
