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
    public class AccountTriggerState {
        public Integer counter = 0;
    }
    public static AccountTriggerState state = new AccountTriggerState();

    @TestVisible
    private static List<Apex_Trigger_Handler_Setting__mdt> settings {
        get {
            if (settings == null) {
                settings = [
                    SELECT Id, Label, SObject__c, Trigger_Event__c, Handler_Class__c, Execution_Order__c, Tag__c
                    FROM Apex_Trigger_Handler_Setting__mdt
                    WHERE Active__c = TRUE
                    ORDER BY SObject__c, Trigger_Event__c, Execution_Order__c
                ];
            }
            return settings;
        }
        set;
    }

    private static Map<SObjectType, Map<TriggerOperation, List<Apex_Trigger_Handler_Setting__mdt>>> handlerSettings {
        get {
            if (handlerSettings == null) {
                handlerSettings = new Map<SObjectType, Map<TriggerOperation, List<Apex_Trigger_Handler_Setting__mdt>>>();
                SObjectType preObjectType = null;
                TriggerOperation preTriggerEvent = null;
                for (Apex_Trigger_Handler_Setting__mdt setting : settings) {
                    SObjectType objectType = Schema.getGlobalDescribe().get(setting.SObject__c);
                    if (objectType == null) {
                        throw new TypeException(
                            'Apex Trigger Handler Setting [' +
                                setting.Label +
                                '] doesn\'t have a valid SObject__c [' +
                                setting.SObject__c +
                                '].'
                        );
                    } else if (preObjectType != objectType) {
                        preObjectType = objectType;
                        preTriggerEvent = null;
                        handlerSettings.put(
                            objectType,
                            new Map<TriggerOperation, List<Apex_Trigger_Handler_Setting__mdt>>()
                        );
                    }

                    TriggerOperation triggerEvent = TriggerOperation.valueOf(setting.Trigger_Event__c);
                    if (preTriggerEvent != triggerEvent) {
                        preTriggerEvent = triggerEvent;
                        handlerSettings.get(objectType)
                            .put(triggerEvent, new List<Apex_Trigger_Handler_Setting__mdt>());
                    }

                    handlerSettings.get(objectType).get(triggerEvent).add(setting);
                }
            }

            return handlerSettings;
        }
        set;
    }

    public List<Triggers.Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent) {
        return load(sObjectType, triggerEvent, null, false);
    }

    public List<Triggers.Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent, String tag) {
        return load(sObjectType, triggerEvent, tag, true);
    }

    private List<Triggers.Handler> load(
        SObjectType sObjectType,
        TriggerOperation triggerEvent,
        String tag,
        Boolean needCheckTag
    ) {
        List<Triggers.Handler> handlers = new List<Triggers.Handler>();
        if (handlerSettings.containsKey(sObjectType) && handlerSettings.get(sObjectType).containsKey(triggerEvent)) {
            for (Apex_Trigger_Handler_Setting__mdt setting : handlerSettings.get(sObjectType).get(triggerEvent)) {
                if (!needCheckTag || setting.Tag__c == tag) {
                    Type handlerType = Type.forName(setting.Handler_Class__c);
                    if (handlerType == null || !Triggers.Handler.class.isAssignableFrom(handlerType)) {
                        throw new TypeException(
                            'Apex Trigger Handler Setting [' +
                                setting.Label +
                                '] doesn\'t have a valid Handler_Class__c [' +
                                setting.Handler_Class__c +
                                '].'
                        );
                    }
                    handlers.add((Triggers.Handler) handlerType.newInstance());
                }
            }
        }
        return handlers;
    }
}
