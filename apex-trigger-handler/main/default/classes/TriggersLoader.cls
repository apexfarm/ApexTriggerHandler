/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

public class TriggersLoader implements Triggers.Loader {
    private final static Map<String, Map<String, List<TriggerHandlerRegistry__mdt>>> HANDLER_SETTINGS { get; set; }
    private final static Map<String, Type> HANDLER_TYPES = new Map<String, Type>();

    static {
        HANDLER_SETTINGS = new Map<String, Map<String, List<TriggerHandlerRegistry__mdt>>>();
    }

    public List<Type> load(String sobjectName, String triggerEventName) {
        List<Type> handlerTypes = new List<Type>();
        if (
            HANDLER_SETTINGS.containsKey(sobjectName) && HANDLER_SETTINGS.get(sobjectName).containsKey(triggerEventName)
        ) {
            for (TriggerHandlerRegistry__mdt setting : HANDLER_SETTINGS.get(sobjectName).get(triggerEventName)) {
                handlerTypes.add(getHandlerType(setting.HandlerClass__c));
            }
        }
        return handlerTypes;
    }

    private void loadHandlerSettings(String sobjectName) {
        if (!HANDLER_SETTINGS.containsKey(sobjectName)) {
            List<TriggerHandlerRegistry__mdt> settings = [
                SELECT Id, Label, SObject__c, TriggerEvent__c, HandlerClass__c, ExecutionOrder__c
                FROM TriggerHandlerRegistry__mdt
                WHERE IsActive__c = TRUE AND SObject__c = :sobjectName
                ORDER BY SObject__c, TriggerEvent__c, ExecutionOrder__c
            ];

            setHandlerSettings(sobjectName, settings);
        }
    }

    @TestVisible
    private static void setHandlerSettings(String sobjectName, List<TriggerHandlerRegistry__mdt> settings) {
        HANDLER_SETTINGS.put(sobjectName, new Map<String, List<TriggerHandlerRegistry__mdt>>());

        String preTriggerEvent = null;
        for (TriggerHandlerRegistry__mdt setting : settings) {
            String triggerEvent = setting.TriggerEvent__c;
            if (preTriggerEvent != triggerEvent) {
                preTriggerEvent = triggerEvent;
                HANDLER_SETTINGS.get(sobjectName).put(triggerEvent, new List<TriggerHandlerRegistry__mdt>());
            }

            HANDLER_SETTINGS.get(sobjectName).get(triggerEvent).add(setting);
        }
    }

    private Type getHandlerType(String className) {
        if (!HANDLER_TYPES.containsKey(className)) {
            Type handlerType = Type.forName(className);
            if (handlerType == null) {
                throw new TypeException('Handler class [' + className + '] cannot be found.');
            }
            HANDLER_TYPES.put(className, handlerType);
        }
        return HANDLER_TYPES.get(className);
    }
}
