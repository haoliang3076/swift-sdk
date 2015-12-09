/**
 * Copyright IBM Corporation 2015
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

import Foundation
import ObjectMapper

/**
 *  If a result has multiple transcription possibilities, there is an alternative 
 *  provided with a confidence rating.
 */
public struct SpeechToTextAlternative: Mappable
{
    var transcript: String?
    var confidence: Double?
    
    public init?(_ map: Map) {}
    
    public mutating func mapping(map: Map) {
        transcript          <- map["transcript"]
        confidence          <- map["confidence"]
        
    }
}