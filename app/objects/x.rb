class X
  def self.app_name
    "towers of trust"
  end

  def self.time_now
    Time.current
  end

  def self.queries
    Queries.new
  end

  def self.translations
    Translations.new
  end

  def self.factory
    Factory.new
  end

  def self.fixture
    Fixture.new
  end

  def self.dev_service
    DevService.new
  end

  def self.services
    Services.new
  end

  def self.presenter
    Presenter.new
  end

  def self.exceptions
    Exceptions.new
  end

  def self.ex
    exceptions
  end

  def self.t(key)
    translations.get(key)
  end

  def self.get_pagination(a)
    if a.is_a?(ActionController::Parameters)
      result = Pagination.new
      offset = a["offset"].presence || 0
      offset = offset.to_i
      page_size = a["page_size"].presence || 30
      page_size = page_size.to_i
      total_count = nil
      result.set(offset, page_size, total_count)
      result
    elsif a == "no_pagination"
      Pagination.new.unset_paginate
    else fail
    end
  end

  def self.logged_in?(controller)
    !controller.current_user.nil?
  end

  def self.rails_url_for(options)
    url_helpers.url_for(options)
  end

  def self.rails_translate(key)
    I18n.t key
  end

  def self.available_locales
    I18n.available_locales
  end

  def self.set_request_locale(locale)
    I18n.locale = locale
    self
  end

  def self.url_helpers
    Rails.application.routes.url_helpers
  end

  def self.path_for(key, a = nil)
    Url.new.path_for(key, a)
  end

  def self.form_authenticity_token(view)
    # todo: add controller
    # controller.helpers.form_authenticity_token()
    view.form_authenticity_token()
  end

  def self.test?
    Rails.env.test?
  end

  def self.nice_env?
    Rails.env.test? || Rails.env.development?
  end

  def self.log(object)
    puts object
  end

  def self.transaction(&block)
    ActiveRecord::Base.transaction(&block)
    self
  end

  def self.random_email
    "random#{rand(1000)}@email.com"
  end

  def self.github_url
    "https://github.com/hauska7/towers-of-trust"
  end

  def self.contact_email
    "grzegorz.hauska@gmail.com"
  end

  def self.default_password
    "123456"
  end

  def self.name_from_email(email)
    email.split("@").first
  end

  def self.guard(what, a = nil)
    case what
    when "dev_helper"
      fail unless nice_env?
    when "leave_group"
      if a.is_a?(Hash)
        if a.key?(:current_user) && a.key?(:gmember)
          ex.guard! if a[:gmember].member != a[:current_user]
        else fail
        end
      else fail
      end
    when "trust_back"
      if a.is_a?(Hash)
        if a.key?(:current_user) && a.key?(:trust)
          ex.guard! if a[:trust].truster.member != a[:current_user]
        else fail
        end
      else fail
      end
    when "trust_unblock"
      if a.is_a?(Hash)
        if a.key?(:current_user) && a.key?(:trust_block)
          ex.guard! if a[:trust_block].trustee.member != a[:current_user]
        else fail
        end
      else fail
      end
    else fail
    end
  end

  def self.generate_color
    number1 = rand(56) + 200
    number1 = number1.to_s(16)
    number2 = rand(56) + 200
    number2 = number2.to_s(16)
    number3 = rand(56) + 200
    number3 = number3.to_s(16)
  
    "##{number1}#{number2}#{number3}"
  end

  def self.generate_password
    Devise.friendly_token.first(8)
  end

  def self.generate_play_around_email
    "#{Devise.friendly_token.first(8)}@towers-of-trust.com"
  end

  def self.generate_tower_name(group)
    towers = group.query("towers")
    highest_number = towers.map(&:name).map do |name|
       Integer(name)
    rescue ArgumentError
      nil
    end
      .compact
      .max || 0
    
    result = highest_number + 1
    result.to_s
  end

  def self.cast_flag(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def self.time_in_half_a_year
    6.months.from_now
  end

  def self.pp(object)
    # todo: use pp but return output as result instead of to std
    object.to_s
  end
end