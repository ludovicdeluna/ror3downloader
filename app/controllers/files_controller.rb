#coding: UTF-8
# Fichier d'origine des tests ayant amené la création de Medias, Sessions, Notes
class FilesController < ApplicationController
  def index
    @avatars = Files.where("uploaded_at is not null")
  end

  def create
    avatar = Files.new(uploaded_file: params[:file_tag], session_id: 328, file_limits: {maxsize: 3, types: ["jpg","jpeg","png","gif"]})
    if avatar.is_file?
      if avatar.save
        render text: "<a href=\"#{root_path}\">Retry</a><br />Fichier sauvegardé : #{avatar.name} <br /><img src=\"#{avatar.path(root_url)}\" alt=\"#\">"
      else
        render text: "<a href=\"#{root_path}\">Retry</a><br />Sauvegarde erreur"
      end
    else
      if params[:file_tag_id] && params[:file_tag_id] != ''
        avatar = Files.where(id: params[:file_tag_id].to_i).first if params[:file_tag_id]
        if avatar && avatar.is_file?
          render text: "<a href=\"#{root_path}\">Retry</a><br />Rappel du fichier #{avatar.name}<br /><img src=\"#{avatar.path(root_url)}\" alt=\"#\">"
        else
          render text: "<a href=\"#{root_path}\">Retry</a><br />Oooops ! Votre fichier n'est plus disponible. Merci de le télécharger à nouveau"
        end
      else
        render text: "<a href=\"#{root_path}\">Retry</a><br />No file submitted"
      end
    end
  end

  def destroy
    avatar = Files.where(id: params[:id]).first
    if avatar
      if avatar.destroy
        render text: "<a href=\"#{root_path}\">Retry</a><br />Le fichier #{params[:id]} a été supprimé"
      else
        render text: "<a href=\"#{root_path}\">Retry</a><br />Impossible de supprimer le fichier #{params[:id]}"
      end
    else
      render text: "<a href=\"#{root_path}\">Retry</a><br />Le fichier #{params[:id]} n'existe pas"
    end
  end

end
