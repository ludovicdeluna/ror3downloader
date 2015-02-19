#coding: UTF-8
class Session < ActiveRecord::Base
  attr_protected [:session, :data, :updated_at], :as => :admin

  has_many :medias, dependent: :destroy

  scope :current, lambda{ |request| where(session_id: request.session_options[:id]) }
  scope :old, lambda{ where('updated_at <= ?', Date.today-1.days) }
 
end
