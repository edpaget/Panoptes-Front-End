React = require 'react'
Select = require 'react-select'
apiClient = require '../api/client'
debounce = require 'debounce'

module.exports = React.createClass
  displayName: 'TagSearch'

  getDefaultProps: ->
    multi: true

  searchTags: (value, callback) ->
    if value is ''
      callback null, { options: [] }
    else
      apiClient.type('tags').get search: "#{value}", page_size: 10
        .then (tags) =>
          opts = for tag in tags
            { value: tag.name, label: tag.name }
          callback null, {
            options: opts
          }

  saveCurrent: ({target}) ->
    value = target.value
    unless value is ''
      @refs.tagSearch.addValue(value)

  handleInputChange: ({target}) ->
    value = target.value
    if value.slice("-1") is ","
      @refs.tagSearch.addValue(value.slice(0, -1))

  render: ->
    value = @props.value.join(',')
    <Select
      ref="tagSearch"
      multi={@props.multi}
      name={@props.name}
      value={value}
      placeholder="Tags:"
      className="search standard-input"
      closeAfterClick={false}
      onBlur={@saveCurrent}
      onChange={@props.onChange}
      onInputChange={@handleInputChange}
      asyncOptions={debounce(@searchTags, 200)} />
