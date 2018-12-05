# frozen_string_literal: true

require 'action_mailer'

ActionMailer::Base.delivery_method = :test

class MailerOtherKlass; end

class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def self.trigger(arg)
    "msg: #{arg}"
  end

  def email1
    self.class.trigger('hello')
    mail(to: 'to@example.com') do |format|
      format.text { render plain: 'Hello Mikel!' }
    end
  end

  def email2(arg)
    self.class.trigger(arg)
    mail(to: 'to@example.com') do |format|
      format.text { render plain: 'Hello Mikel!' }
    end
  end
end
