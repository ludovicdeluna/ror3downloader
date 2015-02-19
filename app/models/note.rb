#coding: UTF-8
class Note < ActiveRecord::Base

  belongs_to :media

  attr_accessible :description
  attr_protected  [:media_id], :as => :admin
 
end
