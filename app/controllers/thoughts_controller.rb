class ThoughtsController < ApplicationController

  # TODO: I maybe don't need all of these...
  helper :application, :todos, :notes

  # GET /thoughts
  # GET /thoughts.xml
  def index
    @page_title = "TRACKS::Thoughts overview"
    @count = current_user.thoughts.size
    @thoughts = Thought.find(:all)
    @no_thoughts = @thoughts.empty?
   
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @thoughts }
    end
  end

  # GET /thoughts/1
  # GET /thoughts/1.xml
  def show
    @page_title = "TRACKS::Show thought"
    @thought = Thought.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @thought }
    end
  end

  # GET /thoughts/new
  # GET /thoughts/new.xml
  def new
    @page_title = "TRACKS::New thought"
    @thought = Thought.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @thought }
    end
  end

  # GET /thoughts/1/edit
  def edit
    @page_title = "TRACKS::Edit thought"
    @thought = Thought.find(params[:id])
  end

  # POST /thoughts
  # POST /thoughts.xml
  def create
    @page_title = "TRACKS::Add a thought"
    @thought = Thought.new(params[:thought])

    respond_to do |format|
      if @thought.save
        flash[:notice] = 'Thought was successfully created.'
        format.html { redirect_to(@thought) }
        format.xml  { render :xml => @thought, :status => :created, :location => @thought }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @thought.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /thoughts/1
  # PUT /thoughts/1.xml
  def update
    @thought = Thought.find(params[:id])

    respond_to do |format|
      if @thought.update_attributes(params[:thought])
        flash[:notice] = 'Thought was successfully updated.'
        format.html { redirect_to(@thought) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @thought.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /thoughts/1
  # DELETE /thoughts/1.xml
  def destroy
    @thought = Thought.find(params[:id])
    @thought.destroy

    respond_to do |format|
      format.html { redirect_to(thoughts_url) }
      format.xml  { head :ok }
    end
  end
  
   def alphabetize
    @thoughts = current_user.thoughts.alphabetize()
    init_not_done_counts(['thought']) #TODO lookup what this is/does
  end

end
