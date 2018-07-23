/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
// swiftlint:disable file_length

import Foundation

/**
 The IBM Watson&trade; Assistant service combines machine learning, natural language understanding, and integrated
 dialog tools to create conversation flows between your apps and your users.
 */
public class Assistant {

    /// The base URL to use when contacting the service.
    public var serviceURL = "https://gateway.watsonplatform.net/assistant/api"

    /// The default HTTP headers for all requests to the service.
    public var defaultHeaders = [String: String]()

    private let session = URLSession(configuration: URLSessionConfiguration.default)
    private var authMethod: AuthenticationMethod
    private let domain = "com.ibm.watson.developer-cloud.AssistantV1"
    private let version: String

    /**
     Create a `Assistant` object.

     - parameter username: The username used to authenticate with the service.
     - parameter password: The password used to authenticate with the service.
     - parameter version: The release date of the version of the API to use. Specify the date
       in "YYYY-MM-DD" format.
     */
    public init(username: String, password: String, version: String) {
        self.authMethod = BasicAuthentication(username: username, password: password)
        self.version = version
    }

    /**
     Create a `Assistant` object.

     - parameter version: The release date of the version of the API to use. Specify the date
       in "YYYY-MM-DD" format.
     - parameter apiKey: An API key for IAM that can be used to obtain access tokens for the service.
     - parameter iamUrl: The URL for the IAM service.
     */
    public init(version: String, apiKey: String, iamUrl: String? = nil) {
        self.version = version
        self.authMethod = IAMAuthentication(apiKey: apiKey, url: iamUrl)
    }

    /**
     Create a `Assistant` object.

     - parameter version: The release date of the version of the API to use. Specify the date
       in "YYYY-MM-DD" format.
     - parameter accessToken: An access token for the service.
     */
    public init(version: String, accessToken: String) {
        self.version = version
        self.authMethod = IAMAccessToken(accessToken: accessToken)
    }

    public func accessToken(_ newToken: String) {
        if self.authMethod is IAMAccessToken {
            self.authMethod = IAMAccessToken(accessToken: newToken)
        }
    }

    /**
     If the response or data represents an error returned by the Watson Assistant service,
     then return NSError with information about the error that occured. Otherwise, return nil.

     - parameter data: Raw data returned from the service that may represent an error.
     - parameter response: the URL response returned from the service.
     */
    private func errorResponseDecoder(data: Data, response: HTTPURLResponse) -> Error {

        let code = response.statusCode
        do {
            let json = try JSONDecoder().decode([String: JSON].self, from: data)
            var userInfo: [String: Any] = [:]
            return NSError(domain: domain, code: code, userInfo: userInfo)
        } catch {
            return NSError(domain: domain, code: code, userInfo: nil)
        }
    }

    /**
     Get response to user input.

     Get a response to a user's input.
     There is no rate limit for this operation.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter request: The message to be sent. This includes the user's input, along with optional intents,
       entities, and context from the last response.
     - parameter nodesVisitedDetails: Whether to include additional diagnostic information about the dialog nodes that
       were visited during processing of the message.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func message(
        workspaceID: String,
        request: MessageRequest? = nil,
        nodesVisitedDetails: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<MessageResponse>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encodeIfPresent(request) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let nodesVisitedDetails = nodesVisitedDetails {
            let queryParameter = URLQueryItem(name: "nodes_visited_details", value: "\(nodesVisitedDetails)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/message"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     List workspaces.

     List the workspaces associated with a Watson Assistant service instance.
     This operation is limited to 500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listWorkspaces(
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<WorkspaceCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + "/v1/workspaces",
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create workspace.

     Create a workspace based on component objects. You must provide workspace components defining the content of the
     new workspace.
     This operation is limited to 30 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter properties: The content of the new workspace.
       The maximum size for this data is 50MB. If you need to import a larger workspace, consider importing the
       workspace without intents and entities and then adding them separately.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createWorkspace(
        properties: CreateWorkspace? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Workspace>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encodeIfPresent(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + "/v1/workspaces",
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get information about a workspace.

     Get information about a workspace, optionally including all workspace content.
     With **export**=`false`, this operation is limited to 6000 requests per 5 minutes. With **export**=`true`, the
     limit is 20 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getWorkspace(
        workspaceID: String,
        export: Bool? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<WorkspaceExport>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update workspace.

     Update an existing workspace with new or modified data. You must provide component objects defining the content of
     the updated workspace.
     This operation is limited to 30 request per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter properties: Valid data defining the new and updated workspace content.
       The maximum size for this data is 50MB. If you need to import a larger amount of workspace data, consider
       importing components such as intents and entities using separate operations.
     - parameter append: Whether the new data is to be appended to the existing data in the workspace. If
       **append**=`false`, elements included in the new data completely replace the corresponding existing elements,
       including all subelements. For example, if the new data includes **entities** and **append**=`false`, all
       existing entities in the workspace are discarded and replaced with the new entities.
       If **append**=`true`, existing elements are preserved, and the new elements are added. If any elements in the new
       data collide with existing elements, the update request fails.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateWorkspace(
        workspaceID: String,
        properties: UpdateWorkspace? = nil,
        append: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Workspace>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encodeIfPresent(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let append = append {
            let queryParameter = URLQueryItem(name: "append", value: "\(append)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete workspace.

     Delete a workspace from the service instance.
     This operation is limited to 30 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteWorkspace(
        workspaceID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List intents.

     List the intents for a workspace.
     With **export**=`false`, this operation is limited to 2000 requests per 30 minutes. With **export**=`true`, the
     limit is 400 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listIntents(
        workspaceID: String,
        export: Bool? = nil,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<IntentCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create intent.

     Create a new intent.
     This operation is limited to 2000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The name of the intent. This string must conform to the following restrictions:
       - It can contain only Unicode alphanumeric, underscore, hyphen, and dot characters.
       - It cannot begin with the reserved prefix `sys-`.
       - It must be no longer than 128 characters.
     - parameter description: The description of the intent. This string cannot contain carriage return, newline, or
       tab characters, and it must be no longer than 128 characters.
     - parameter examples: An array of user input examples for the intent.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createIntent(
        workspaceID: String,
        intent: String,
        description: String? = nil,
        examples: [CreateExample]? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Intent>?, Error?) -> Void)
    {
        // construct body
        let createIntentRequest = CreateIntent(intent: intent, description: description, examples: examples)
        guard let body = try? JSONEncoder().encode(createIntentRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get intent.

     Get information about an intent, optionally including all intent content.
     With **export**=`false`, this operation is limited to 6000 requests per 5 minutes. With **export**=`true`, the
     limit is 400 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getIntent(
        workspaceID: String,
        intent: String,
        export: Bool? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<IntentExport>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update intent.

     Update an existing intent with new or modified data. You must provide component objects defining the content of the
     updated intent.
     This operation is limited to 2000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter newIntent: The name of the intent. This string must conform to the following restrictions:
       - It can contain only Unicode alphanumeric, underscore, hyphen, and dot characters.
       - It cannot begin with the reserved prefix `sys-`.
       - It must be no longer than 128 characters.
     - parameter newDescription: The description of the intent.
     - parameter newExamples: An array of user input examples for the intent.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateIntent(
        workspaceID: String,
        intent: String,
        newIntent: String? = nil,
        newDescription: String? = nil,
        newExamples: [CreateExample]? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Intent>?, Error?) -> Void)
    {
        // construct body
        let updateIntentRequest = UpdateIntent(intent: newIntent, description: newDescription, examples: newExamples)
        guard let body = try? JSONEncoder().encode(updateIntentRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete intent.

     Delete an intent from a workspace.
     This operation is limited to 2000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteIntent(
        workspaceID: String,
        intent: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List user input examples.

     List the user input examples for an intent.
     This operation is limited to 2500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listExamples(
        workspaceID: String,
        intent: String,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<ExampleCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)/examples"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create user input example.

     Add a new user input example to an intent.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter text: The text of a user input example. This string must conform to the following restrictions:
       - It cannot contain carriage return, newline, or tab characters.
       - It cannot consist of only whitespace characters.
       - It must be no longer than 1024 characters.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createExample(
        workspaceID: String,
        intent: String,
        text: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Example>?, Error?) -> Void)
    {
        // construct body
        let createExampleRequest = CreateExample(text: text)
        guard let body = try? JSONEncoder().encode(createExampleRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)/examples"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get user input example.

     Get information about a user input example.
     This operation is limited to 6000 requests per 5 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter text: The text of the user input example.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getExample(
        workspaceID: String,
        intent: String,
        text: String,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Example>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)/examples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update user input example.

     Update the text of a user input example.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter text: The text of the user input example.
     - parameter newText: The text of the user input example. This string must conform to the following restrictions:
       - It cannot contain carriage return, newline, or tab characters.
       - It cannot consist of only whitespace characters.
       - It must be no longer than 1024 characters.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateExample(
        workspaceID: String,
        intent: String,
        text: String,
        newText: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Example>?, Error?) -> Void)
    {
        // construct body
        let updateExampleRequest = UpdateExample(text: newText)
        guard let body = try? JSONEncoder().encode(updateExampleRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)/examples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete user input example.

     Delete a user input example from an intent.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter intent: The intent name.
     - parameter text: The text of the user input example.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteExample(
        workspaceID: String,
        intent: String,
        text: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/intents/\(intent)/examples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List counterexamples.

     List the counterexamples for a workspace. Counterexamples are examples that have been marked as irrelevant input.
     This operation is limited to 2500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listCounterexamples(
        workspaceID: String,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<CounterexampleCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/counterexamples"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create counterexample.

     Add a new counterexample to a workspace. Counterexamples are examples that have been marked as irrelevant input.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter text: The text of a user input marked as irrelevant input. This string must conform to the following
       restrictions:
       - It cannot contain carriage return, newline, or tab characters
       - It cannot consist of only whitespace characters
       - It must be no longer than 1024 characters.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createCounterexample(
        workspaceID: String,
        text: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Counterexample>?, Error?) -> Void)
    {
        // construct body
        let createCounterexampleRequest = CreateCounterexample(text: text)
        guard let body = try? JSONEncoder().encode(createCounterexampleRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/counterexamples"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get counterexample.

     Get information about a counterexample. Counterexamples are examples that have been marked as irrelevant input.
     This operation is limited to 6000 requests per 5 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter text: The text of a user input counterexample (for example, `What are you wearing?`).
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getCounterexample(
        workspaceID: String,
        text: String,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Counterexample>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/counterexamples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update counterexample.

     Update the text of a counterexample. Counterexamples are examples that have been marked as irrelevant input.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter text: The text of a user input counterexample (for example, `What are you wearing?`).
     - parameter newText: The text of a user input counterexample.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateCounterexample(
        workspaceID: String,
        text: String,
        newText: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Counterexample>?, Error?) -> Void)
    {
        // construct body
        let updateCounterexampleRequest = UpdateCounterexample(text: newText)
        guard let body = try? JSONEncoder().encode(updateCounterexampleRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/counterexamples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete counterexample.

     Delete a counterexample from a workspace. Counterexamples are examples that have been marked as irrelevant input.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter text: The text of a user input counterexample (for example, `What are you wearing?`).
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteCounterexample(
        workspaceID: String,
        text: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/counterexamples/\(text)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List entities.

     List the entities for a workspace.
     With **export**=`false`, this operation is limited to 1000 requests per 30 minutes. With **export**=`true`, the
     limit is 200 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listEntities(
        workspaceID: String,
        export: Bool? = nil,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<EntityCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create entity.

     Create a new entity.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter properties: The content of the new entity.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createEntity(
        workspaceID: String,
        properties: CreateEntity,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Entity>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get entity.

     Get information about an entity, optionally including all entity content.
     With **export**=`false`, this operation is limited to 6000 requests per 5 minutes. With **export**=`true`, the
     limit is 200 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getEntity(
        workspaceID: String,
        entity: String,
        export: Bool? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<EntityExport>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update entity.

     Update an existing entity with new or modified data. You must provide component objects defining the content of the
     updated entity.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter properties: The updated content of the entity. Any elements included in the new data will completely
       replace the equivalent existing elements, including all subelements. (Previously existing subelements are not
       retained unless they are also included in the new data.) For example, if you update the values for an entity, the
       previously existing values are discarded and replaced with the new values specified in the update.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateEntity(
        workspaceID: String,
        entity: String,
        properties: UpdateEntity,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Entity>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete entity.

     Delete an entity from a workspace.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteEntity(
        workspaceID: String,
        entity: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List entity values.

     List the values for an entity.
     This operation is limited to 2500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listValues(
        workspaceID: String,
        entity: String,
        export: Bool? = nil,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<ValueCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Add entity value.

     Create a new value for an entity.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter properties: The new entity value.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createValue(
        workspaceID: String,
        entity: String,
        properties: CreateValue,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Value>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get entity value.

     Get information about an entity value.
     This operation is limited to 6000 requests per 5 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter export: Whether to include all element content in the returned data. If **export**=`false`, the
       returned data includes only information about the element itself. If **export**=`true`, all content, including
       subelements, is included.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getValue(
        workspaceID: String,
        entity: String,
        value: String,
        export: Bool? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<ValueExport>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let export = export {
            let queryParameter = URLQueryItem(name: "export", value: "\(export)")
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update entity value.

     Update an existing entity value with new or modified data. You must provide component objects defining the content
     of the updated entity value.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter properties: The updated content of the entity value.
       Any elements included in the new data will completely replace the equivalent existing elements, including all
       subelements. (Previously existing subelements are not retained unless they are also included in the new data.)
       For example, if you update the synonyms for an entity value, the previously existing synonyms are discarded and
       replaced with the new synonyms specified in the update.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateValue(
        workspaceID: String,
        entity: String,
        value: String,
        properties: UpdateValue,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Value>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete entity value.

     Delete a value from an entity.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteValue(
        workspaceID: String,
        entity: String,
        value: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List entity value synonyms.

     List the synonyms for an entity value.
     This operation is limited to 2500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listSynonyms(
        workspaceID: String,
        entity: String,
        value: String,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<SynonymCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)/synonyms"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Add entity value synonym.

     Add a new synonym to an entity value.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter synonym: The text of the synonym. This string must conform to the following restrictions:
       - It cannot contain carriage return, newline, or tab characters.
       - It cannot consist of only whitespace characters.
       - It must be no longer than 64 characters.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createSynonym(
        workspaceID: String,
        entity: String,
        value: String,
        synonym: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Synonym>?, Error?) -> Void)
    {
        // construct body
        let createSynonymRequest = CreateSynonym(synonym: synonym)
        guard let body = try? JSONEncoder().encode(createSynonymRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)/synonyms"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get entity value synonym.

     Get information about a synonym of an entity value.
     This operation is limited to 6000 requests per 5 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter synonym: The text of the synonym.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getSynonym(
        workspaceID: String,
        entity: String,
        value: String,
        synonym: String,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Synonym>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)/synonyms/\(synonym)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update entity value synonym.

     Update an existing entity value synonym with new text.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter synonym: The text of the synonym.
     - parameter newSynonym: The text of the synonym. This string must conform to the following restrictions:
       - It cannot contain carriage return, newline, or tab characters.
       - It cannot consist of only whitespace characters.
       - It must be no longer than 64 characters.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateSynonym(
        workspaceID: String,
        entity: String,
        value: String,
        synonym: String,
        newSynonym: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Synonym>?, Error?) -> Void)
    {
        // construct body
        let updateSynonymRequest = UpdateSynonym(synonym: newSynonym)
        guard let body = try? JSONEncoder().encode(updateSynonymRequest) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)/synonyms/\(synonym)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete entity value synonym.

     Delete a synonym from an entity value.
     This operation is limited to 1000 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter entity: The name of the entity.
     - parameter value: The text of the entity value.
     - parameter synonym: The text of the synonym.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteSynonym(
        workspaceID: String,
        entity: String,
        value: String,
        synonym: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/entities/\(entity)/values/\(value)/synonyms/\(synonym)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List dialog nodes.

     List the dialog nodes for a workspace.
     This operation is limited to 2500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter includeCount: Whether to include information about the number of records returned.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listDialogNodes(
        workspaceID: String,
        pageLimit: Int? = nil,
        includeCount: Bool? = nil,
        sort: String? = nil,
        cursor: String? = nil,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<DialogNodeCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let includeCount = includeCount {
            let queryParameter = URLQueryItem(name: "include_count", value: "\(includeCount)")
            queryParameters.append(queryParameter)
        }
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/dialog_nodes"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Create dialog node.

     Create a new dialog node.
     This operation is limited to 500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter properties: A CreateDialogNode object defining the content of the new dialog node.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func createDialogNode(
        workspaceID: String,
        properties: CreateDialogNode,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<DialogNode>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/dialog_nodes"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Get dialog node.

     Get information about a dialog node.
     This operation is limited to 6000 requests per 5 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter dialogNode: The dialog node ID (for example, `get_order`).
     - parameter includeAudit: Whether to include the audit properties (`created` and `updated` timestamps) in the
       response.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func getDialogNode(
        workspaceID: String,
        dialogNode: String,
        includeAudit: Bool? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<DialogNode>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let includeAudit = includeAudit {
            let queryParameter = URLQueryItem(name: "include_audit", value: "\(includeAudit)")
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/dialog_nodes/\(dialogNode)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Update dialog node.

     Update an existing dialog node with new or modified data.
     This operation is limited to 500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter dialogNode: The dialog node ID (for example, `get_order`).
     - parameter properties: The updated content of the dialog node.
       Any elements included in the new data will completely replace the equivalent existing elements, including all
       subelements. (Previously existing subelements are not retained unless they are also included in the new data.)
       For example, if you update the actions for a dialog node, the previously existing actions are discarded and
       replaced with the new actions specified in the update.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func updateDialogNode(
        workspaceID: String,
        dialogNode: String,
        properties: UpdateDialogNode,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<DialogNode>?, Error?) -> Void)
    {
        // construct body
        guard let body = try? JSONEncoder().encode(properties) else {
            completionHandler(nil, RestError.serializationError)
            return
        }

        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"
        headerParameters["Content-Type"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/dialog_nodes/\(dialogNode)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "POST",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters,
            messageBody: body
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete dialog node.

     Delete a dialog node from a workspace.
     This operation is limited to 500 requests per 30 minutes. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter dialogNode: The dialog node ID (for example, `get_order`).
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteDialogNode(
        workspaceID: String,
        dialogNode: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/dialog_nodes/\(dialogNode)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

    /**
     List log events in a workspace.

     List the events from the log of a specific workspace.
     If **cursor** is not specified, this operation is limited to 40 requests per 30 minutes. If **cursor** is
     specified, the limit is 120 requests per minute. For more information, see **Rate limiting**.

     - parameter workspaceID: Unique identifier of the workspace.
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter filter: A cacheable parameter that limits the results to those matching the specified filter. For
       more information, see the
       [documentation](https://console.bluemix.net/docs/services/conversation/filter-reference.html#filter-query-syntax).
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listLogs(
        workspaceID: String,
        sort: String? = nil,
        filter: String? = nil,
        pageLimit: Int? = nil,
        cursor: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<LogCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let filter = filter {
            let queryParameter = URLQueryItem(name: "filter", value: filter)
            queryParameters.append(queryParameter)
        }
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/v1/workspaces/\(workspaceID)/logs"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completionHandler(nil, RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     List log events in all workspaces.

     List the events from the logs of all workspaces in the service instance.
     If **cursor** is not specified, this operation is limited to 40 requests per 30 minutes. If **cursor** is
     specified, the limit is 120 requests per minute. For more information, see **Rate limiting**.

     - parameter filter: A cacheable parameter that limits the results to those matching the specified filter. You
       must specify a filter query that includes a value for `language`, as well as a value for `workspace_id` or
       `request.context.metadata.deployment`. For more information, see the
       [documentation](https://console.bluemix.net/docs/services/conversation/filter-reference.html#filter-query-syntax).
     - parameter sort: The attribute by which returned results will be sorted. To reverse the sort order, prefix the
       value with a minus sign (`-`). Supported values are `name`, `updated`, and `workspace_id`.
     - parameter pageLimit: The number of records to return in each page of results.
     - parameter cursor: A token identifying the page of results to retrieve.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func listAllLogs(
        filter: String,
        sort: String? = nil,
        pageLimit: Int? = nil,
        cursor: String? = nil,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<LogCollection>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        queryParameters.append(URLQueryItem(name: "filter", value: filter))
        if let sort = sort {
            let queryParameter = URLQueryItem(name: "sort", value: sort)
            queryParameters.append(queryParameter)
        }
        if let pageLimit = pageLimit {
            let queryParameter = URLQueryItem(name: "page_limit", value: "\(pageLimit)")
            queryParameters.append(queryParameter)
        }
        if let cursor = cursor {
            let queryParameter = URLQueryItem(name: "cursor", value: cursor)
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + "/v1/logs",
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseObject(completionHandler: completionHandler)
    }

    /**
     Delete labeled data.

     Deletes all data associated with a specified customer ID. The method has no effect if no data is associated with
     the customer ID.
     You associate a customer ID with data by passing the `X-Watson-Metadata` header with a request that passes data.
     For more information about personal data and customer IDs, see [Information
     security](https://console.bluemix.net/docs/services/conversation/information-security.html).

     - parameter customerID: The customer ID for which all data is to be deleted.
     - parameter headers: A dictionary of request headers to be sent with this request.
     - parameter completionHandler: A function executed when the request completes with a successful result or error
     */
    public func deleteUserData(
        customerID: String,
        headers: [String: String]? = nil,
        completionHandler: @escaping (WatsonResponse<Void>?, Error?) -> Void)
    {
        // construct header parameters
        var headerParameters = defaultHeaders
        if let headers = headers {
            headerParameters.merge(headers) { (_, new) in new }
        }
        headerParameters["Accept"] = "application/json"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "version", value: version))
        queryParameters.append(URLQueryItem(name: "customer_id", value: customerID))

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + "/v1/user_data",
            headerParameters: headerParameters,
            queryItems: queryParameters
        )

        // execute REST request
        request.response(completionHandler: completionHandler)
    }

}
