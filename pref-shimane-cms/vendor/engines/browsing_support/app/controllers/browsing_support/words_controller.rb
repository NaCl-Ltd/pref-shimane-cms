require_dependency "browsing_support/application_controller"

module BrowsingSupport
  class WordsController < ApplicationController
    before_filter :login_required

    layout 'layouts/application'

    def index
      prepare_pagination
    end

    def new
      @word = Word.new
    end

    def create
      @word = Word.new
      @word.set_attributes(params, current_user)
      if @word.save
        flash[:notice] = t('.success')
        redirect_to words_path
      else
        render 'new'
      end
    end

    def edit
      @word = Word.find(params[:id])
      @word.text = @word.text_2h
    end

    def update
      @word = Word.find(params[:id])
      unless @word.editable_by?(@current_user)
        flash[:notice] = t('.not_editable')
        redirect_to words_path
        return
      end
      @word.set_attributes(params, current_user)
      if @word.save
        flash[:notice] = t('.success')
        redirect_to words_path
      else
        render 'edit'
      end
    end

    def destroy
      word = Word.find(params[:id])
      unless word.editable_by?(@current_user)
        flash[:notice] = t('.not_destroyable')
        redirect_to words_path
        return
      end
      word.destroy
      flash[:notice] = t('.success')
      redirect_to words_path
    end

    private

    def prepare_pagination
      @words, @search, @auery = Word.get_paginate(params)
    end
  end
end
