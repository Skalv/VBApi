
module.exports = class ApiRoute

	handle_database = (req, res, request)->
    pool.getConnection (err, connection)->
      if err
        connection.release()
        res.json
          "code": 100
          "status": "Error in connection database"
      console.log "Connected as id #{connection.threadId}"
      connection.query request, (err, rows)->
        connection.release()
        if not err then res.json rows
      connection.on "error", (err)->
        res.json
          "code": 100
          "status": "Error in connection database"

  getPaginableQuery = (req, res, request)->
    params =
      "currentPage":  if req.query.currentPage?  then req.query.currentPage  else 1
      "pageSize":     if req.query.pageSize?     then req.query.pageSize     else 10
      "totalPages":   req.query.totalPages
      "totalRecords": req.query.totalRecords
      "sortKey":      req.query.sortKey
      "order":        req.query.order
    # Default current page is 1
    # Substract 1 to start at 0.
    # Offset is number of the first row return by SQL statement
    offset = (params.currentPage - 1) * params.pageSize
    limite = params.pageSize
    # Define range of result for pagination
    request = "#{request}
    LIMIT #{limite}
    OFFSET #{offset}"
    # Define if result must be sort or not
    if params.sortKey? and params.order?
      request = "#{request}
      ORDER BY #{params.sortKey} #{params.order}"

    return request