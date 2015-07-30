React = require 'react'
Thumbnail = require './thumbnail'
PromiseRenderer = require './promise-renderer'
DropdownForm = require './dropdown-form'
FileButton = require './file-button'
apiClient = require '../api/client'
putFile = require '../lib/put-file'

FileDropTarget = React.createClass
  displayName: 'DragAndDropTarget'

  getDefaultProps: ->
    className: ''
    filterFiles: null
    onDrop: Function.prototype

  getInitialState: ->
    canDrop: false

  eventsToMakeDropWork: ->
    onDragEnter: @handleDragEnter
    onDragOver: @handleDragOver
    onDragLeave: @handleDragLeave
    onDrop: @handleDrop

  render: ->
    className = "file-drop-target #{@props.className}".trim()
    <div {...@props} className={className} data-can-drop={@state.canDrop || null} {...@eventsToMakeDropWork()}>
      {@props.children}
    </div>

  handleDragEnter: (e) ->
    e.preventDefault()
    files = Array::filter.call e.dataTransfer.files, @props.filterFiles ? Boolean
    @setState canDrop: files.length is e.dataTransfer.files.length

  handleDragOver: (e) ->
    e.preventDefault()

  handleDragLeave: (e) ->
    e.preventDefault()
    @setState canDrop: false

  handleDrop: (e) ->
    e.preventDefault()
    if @state.canDrop
      @props.onDrop arguments...
      @setState canDrop: false

MediaIcon = React.createClass
  displayName: 'MediaIcon'

  getDefaultProps: ->
    resource: null
    height: 80
    onDelete: Function.prototype

  getInitialState: ->
    deleting: false

  getMarkdown: (resource) ->
    "![#{resource.metadata.filename}](#{resource.src})"

  render: ->
    <div className="media-icon" style={opacity: 0.5 if @state.deleting}>
      <div className="media-icon-thumbnail-container">
        <DropdownForm label={
          <Thumbnail className="media-icon-thumbnail" src={@props.resource.src} height={@props.height} style={position: 'relative'} />
        }>
          <div className="content-container">
            <img src={@props.resource.src} style={
              maxHeight: '80vh'
              maxWidth: '60vw'
            } />
          </div>
        </DropdownForm>
        <button type="button" className="media-icon-delete-button" disabled={@state.deleting} onClick={@handleDelete}>&times;</button>
      </div>
      <div className="media-icon-label" style={position: 'relative'}>{@props.resource.metadata.filename}</div>
      <textarea className="media-icon-markdown" value={@getMarkdown @props.resource} readOnly style={position: 'relative'} onFocus={@handleMarkdownFocus} />
    </div>

  handleDelete: ->
    console.log "Deleting media resource #{@props.resource.id}"
    @setState deleting: true
    @props.resource.delete().then =>
      @setState deleting: false
      @props.onDelete @props.resource

  handleMarkdownFocus: (e) ->
    e.target.setSelectionRange 0, e.target.value.length

module.exports = React.createClass
  displayName: 'MediaArea'

  getDefaultProps: ->
    resource: null
    link: 'attached_images'
    pageSize: 200
    onAdd: Function.prototype
    onDelete: Function.prototype

  getInitialState: ->
    pendingFiles: []
    pendingMedia: []
    errors: []

  addButtonStyle:
    height: '80px'
    lineHeight: '100px'
    width: '100px'

  render: ->
    window.lastRenderedMediaArea = this
    console.log('Pending', @state.pendingFiles.length, @state.pendingFiles);

    @cachedMediaRequest = @props.resource.get @props.link, page_size: @props.pageSize
      .catch ->
        []

    <PromiseRenderer promise={@cachedMediaRequest}>{(media) =>
      media = [].concat media

      <div className="media-area" style={position: 'relative'}>
        <FileDropTarget style={
          bottom: '3px'
          left: '3px'
          position: 'absolute'
          right: '3px'
          top: '3px'
        } onDrop={@handleDrop} />

        {if media.length is 0
          <small>
            <em>No media</em>
          </small>}

        <ul className="media-area-list">
          {media.map (resource) =>
            if resource in @state.pendingMedia
              null
            else
              <li key={resource.id} className="media-area-item">
                <MediaIcon resource={resource} onDelete={@handleDelete} />
              </li>}

          <li className="media-area-item" style={alignSelf: 'stretch'}>
            <div className="media-icon">
              <FileButton className="media-area-add-button" accept="image/*" multiple style={@addButtonStyle} onSelect={@handleFileSelection}>
                <i className="fa fa-plus fa-3x"></i>
              </FileButton>
              <div className="media-icon-label">Select files</div>
            </div>
          </li>
        </ul>

        {if @props.children?
          <hr />}
        {@props.children}

        {unless @state.pendingFiles.length is 0
          <hr />}
        {@state.pendingFiles.map (file) =>
          <div key={file.name}>
            <small>
              <i className="fa fa-spinner fa-spin"></i>{' '}
              <strong>{file.name}</strong>
            </small>
          </div>}

        {unless @state.errors.length is 0
          <hr />}
        {@state.errors.map ({file, error}) =>
          <div key={file.name}>{error.toString()} ({file.name})</div>}
      </div>
    }</PromiseRenderer>

  handleDrop: (e) ->
    @addFiles Array::slice.call e.dataTransfer.files

  handleDelete: ->
    @refresh()
    @props.onDelete arguments...

  refresh: ->
    console.log 'Refreshing media area'
    @cachedMediaRequest = null
    @forceUpdate()

  handleFileSelection: (e) ->
    console.log "Handling #{e.target.files.length} selected files"
    @addFiles Array::slice.call e.target.files

  addFiles: (files) ->
    console.log "Adding #{files.length} files"
    files.forEach @addFile

  addFile: (file) ->
    console.log "Adding media #{file.name}"
    @state.pendingFiles.push file
    @setState pendingFiles: @state.pendingFiles

    @createLinkedResource file
      .then @uploadMedia.bind this, file
      .then @handleSuccess
      .catch @handleError.bind this, file
      .then @removeFromPending.bind this, file

  createLinkedResource: (file) ->
    console.log "Creating resource for #{file.name}, #{(file.type)}"
    payload =
      media:
        content_type: file.type
        metadata:
          filename: file.name

    apiClient.post @props.resource._getURL(@props.link), payload
      .then (media) =>
        # We get an array here for some reason. Pull the resource out.
        # TODO: Look into this.
        media = [].concat(media)[0]
        @state.pendingMedia.push media
        media

  uploadMedia: (file, media) ->
    console.log "Uploading #{file.name} => #{media.src}"
    putFile media.src, file
      .then =>
        media.refresh().then (media) =>
          # Another weird array.
          [].concat(media)[0]
      .catch (error) =>
        media.delete()
          .then =>
            throw error

  handleSuccess: (media) ->
    console.log "Success! #{media.metadata.filename}"
    pendingMediaIndex = @state.pendingMedia.indexOf media
    @state.pendingMedia.splice pendingMediaIndex, 1
    @setState pendingMedia: @state.pendingMedia
    @props.onAdd media
    media

  handleError: (file, error) ->
    console.log "Got error #{error.message} for #{file.name}"
    @state.errors.push {file, error}
    @setState errors: @state.errors

  removeFromPending: (file) ->
    console.log "No longer pendingFiles: #{file.name}"
    pendingFileIndex = @state.pendingFiles.indexOf file
    @state.pendingFiles.splice pendingFileIndex, 1
    @setState pendingFiles: @state.pendingFiles
