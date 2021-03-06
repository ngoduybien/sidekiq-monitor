class SidekiqMonitor.QueuesTable extends SidekiqMonitor.AbstractJobsTable

  initialize: =>
    options =
      table_selector: 'table.queue-jobs'
      columns:
        jid: 0
        queue: 1
        class_name: 2
        name: 3
        enqueued_at: 4
        started_at: 5
        duration: 6
        message: 7
        status: 8
        result: 9
        args: 10
      column_options: [
        { bVisible: false }
        { bVisible: false }
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.enqueued_at])
        }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.started_at])
        }
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            status = oObj.aData[@columns.status]
            class_name = switch status
              when 'failed'
                'danger'
              when 'complete'
                'success'
              when 'running'
                'primary'
              else
                'info'
            html = """<a href="#" class="btn btn-#{class_name} btn-mini status-value">#{oObj.aData[@columns.status]}</a>"""
            if status == 'failed'
              html += """<a href="#" class="btn btn-mini btn-primary retry-job" data-job-jid="#{oObj.aData[0]}">Retry<a>"""
            """<span class="action-buttons">#{html}</span>"""
        }
        { bVisible: false }
        { bVisible: false }
      ]
    return null unless $(options.table_selector).length

    @queue_select = $('[name=queue_select]')
    @queue_select.selectpicker()
    @queue_select.change =>
      @load_selected_queue()
      @reload_table()
    @queue_select.val(@queue_select.find('option:first').val())
    @load_selected_queue()

    @initialize_with_options(options)

  show_queue_stats: =>
    $.getJSON SidekiqMonitor.settings.api_url("queues/#{@queue}"), (stats) =>
      if stats
        header_cells = ""
        value_cells = ""
        $.each stats.status_counts, (status, count) =>
          header_cells += "<th>#{status}</th>"
          value_cells += "<td>#{count}</td>"
        html = """
          <table class="table table-striped table-condensed table-bordered">
            <tr>#{header_cells}</tr>
            <tr>#{value_cells}</tr>
          </table>
        """
      else
        html = ''
      $('.queue-stats').html(html)

  load_selected_queue: =>
    @queue = @queue_select.val()
    @api_params['queue'] = @queue
    @show_queue_stats()

  on_poll: =>
    @reload_table()

$ ->
  new SidekiqMonitor.QueuesTable
