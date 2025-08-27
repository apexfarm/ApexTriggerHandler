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
    private final static Map<String, Type> HANDLER_TYPES = new Map<String, Type>();

    @TestVisible
    private static List<TriggerHandlerRegistry__mdt> settings {
        get {
            if (settings == null) {
                settings = [
                    SELECT Id, Label, SObject__c, TriggerEvent__c, HandlerClass__c, ExecutionOrder__c, Tag__c
                    FROM TriggerHandlerRegistry__mdt
                    WHERE Active__c = TRUE
                    ORDER BY SObject__c, TriggerEvent__c, ExecutionOrder__c
                ];
            }
            return settings;
        }
        set;
    }

    private static Map<String, Map<TriggerOperation, List<TriggerHandlerRegistry__mdt>>> handlerSettings {
        get {
            if (handlerSettings == null) {
                handlerSettings = new Map<String, Map<TriggerOperation, List<TriggerHandlerRegistry__mdt>>>();

                String preSObjectName = null;
                TriggerOperation preTriggerEvent = null;

                for (TriggerHandlerRegistry__mdt setting : settings) {
                    String sObjectName = setting.SObject__c;
                    if (preSObjectName != sObjectName) {
                        preSObjectName = sObjectName;
                        preTriggerEvent = null;
                        handlerSettings.put(
                            sObjectName,
                            new Map<TriggerOperation, List<TriggerHandlerRegistry__mdt>>()
                        );
                    }

                    TriggerOperation triggerEvent = TriggerOperation.valueOf(setting.TriggerEvent__c);
                    if (preTriggerEvent != triggerEvent) {
                        preTriggerEvent = triggerEvent;
                        handlerSettings.get(sObjectName).put(triggerEvent, new List<TriggerHandlerRegistry__mdt>());
                    }

                    handlerSettings.get(sObjectName).get(triggerEvent).add(setting);
                }
            }

            return handlerSettings;
        }
        set;
    }

    public List<Triggers.Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent) {
        return load(sObjectType.toString(), triggerEvent, null, false);
    }

    public List<Triggers.Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent, String tag) {
        return load(sObjectType.toString(), triggerEvent, tag, true);
    }

    private List<Triggers.Handler> load(
        String sObjectName,
        TriggerOperation triggerEvent,
        String tag,
        Boolean needCheckTag
    ) {
        List<Triggers.Handler> handlers = new List<Triggers.Handler>();
        if (handlerSettings.containsKey(sObjectName) && handlerSettings.get(sObjectName).containsKey(triggerEvent)) {
            for (TriggerHandlerRegistry__mdt setting : handlerSettings.get(sObjectName).get(triggerEvent)) {
                if (!needCheckTag || setting.Tag__c == tag) {
                    if (!HANDLER_TYPES.containsKey(setting.HandlerClass__c)) {
                        Type handlerType = Type.forName(setting.HandlerClass__c);
                        if (handlerType == null || !Triggers.Handler.class.isAssignableFrom(handlerType)) {
                            throw new TypeException(
                                'Apex Trigger Handler Setting [' +
                                    setting.Label +
                                    '] doesn\'t have a valid HandlerClass__c [' +
                                    setting.HandlerClass__c +
                                    '].'
                            );
                        }
                        HANDLER_TYPES.put(setting.HandlerClass__c, handlerType);
                    }
                    Type handlerType = HANDLER_TYPES.get(setting.HandlerClass__c);
                    handlers.add((Triggers.Handler) handlerType.newInstance());
                }
            }
        }
        return handlers;
    }
}
