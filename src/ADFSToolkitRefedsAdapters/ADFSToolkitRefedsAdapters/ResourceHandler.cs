// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using ADFSTk.Resources;

namespace ADFSTk
{
    internal static class ResourceHandler
    {
        public static string GetResource(string resourceName, int lcid)
        {
            //Log.WriteEntry("Get resource string: " + resourceName + " with lcid: " + lcid, EventLogEntryType.Information, 335);
            if (lcid != Constants.Lcid.En && lcid != Constants.Lcid.Sv)
            {
                lcid = Constants.Lcid.Sv;
            }
            LangText text = (from tt in texts.Where(t => t.Key == resourceName && t.Lcid == lcid) select tt).SingleOrDefault();
            if (text == null)
            {
                throw new ArgumentNullException();

            }
            return text.Value;
            //if (String.IsNullOrEmpty(resourceName))
            //{
            //    throw new ArgumentNullException("resourceName");
            //}

            //return StringResources.ResourceManager.GetString(resourceName, new CultureInfo(lcid));
        }

        public static string GetPresentationResource(string resourceName, int lcid)
        {
            if (String.IsNullOrEmpty(resourceName))
            {
                throw new ArgumentNullException("resourceName");
            }
            return PresentationResources.ResourceManager.GetString(resourceName, new CultureInfo(lcid));
        }
        private static List<LangText> texts =
            new List<LangText>()
            {
                //en
                new LangText(){Key="AdminFriendlyNameMFA",Lcid=9,Value="Forms Authentication (RefedsMFA)"},
                new LangText(){Key="AdminFriendlyNameSFA",Lcid=9,Value="Forms Authentication (RefedsSFA)"},
                new LangText(){Key="Description",Lcid=9,Value=""},
                new LangText(){Key="FriendlyName",Lcid=9,Value=""},
                new LangText(){Key="PageIntroductionTitle",Lcid=9,Value="Enter your password"},
                new LangText(){Key="PageIntroductionText",Lcid=9,Value=""},
                new LangText(){Key="PagePasswordLabel",Lcid=9,Value="Password"},
                //new LangText(){Key="AuthPageTemplate",Lcid=9,Value=""},
                new LangText(){Key="PageTitle",Lcid=9,Value="PageTitle"},
                new LangText(){Key="SubmitButtonLabel",Lcid=9,Value="Sign in"},
                new LangText(){Key="AuthenticationFailed",Lcid=9,Value="AuthenticationFailed"},
                new LangText(){Key="ErrorInvalidSessionId",Lcid=9,Value="ErrorInvalidSessionId"},
                new LangText(){Key="ErrorInvalidContext",Lcid=9,Value="ErrorInvalidContext"},
                new LangText(){Key="ErrorNoUserIdentity",Lcid=9,Value="ErrorNoUserIdentity"},
                new LangText(){Key="ErrorNoAnswerProvided",Lcid=9,Value="ErrorNoAnswerProvided"},
                new LangText(){Key="ErrorFailSelected",Lcid=9,Value="ErrorFailSelected"},
                new LangText(){Key="ChoiceSuccess",Lcid=9,Value="ChoiceSuccess"},
                new LangText(){Key="ChoiceFail",Lcid=9,Value="ChoiceFail"},
                new LangText(){Key="UserChoice",Lcid=9,Value="UserChoice"},
                new LangText(){Key="FailedLogin",Lcid=9,Value="Incorrect password. Type the correct password, and try again."},
                //sv
                new LangText(){Key="AdminFriendlyNameMFA",Lcid=29,Value="Forms autentisering (RefedsMFA)"},
                new LangText(){Key="AdminFriendlyNameSFA",Lcid=29,Value="Forms autentisering (RefedsSFA)"},
                new LangText(){Key="Description",Lcid=29,Value="Forms autentisering (Refeds)"},
                new LangText(){Key="FriendlyName",Lcid=29,Value=""},
                new LangText(){Key="PageIntroductionTitle",Lcid=29,Value="Skriv in ditt lösenord"},
                new LangText(){Key="PageIntroductionText",Lcid=29,Value=""},
                new LangText(){Key="PagePasswordLabel",Lcid=29,Value="Lösenord"},
                //new LangText(){Key="AuthPageTemplate",Lcid=29,Value=""},
                new LangText(){Key="PageTitle",Lcid=29,Value="PageTitle"},
                new LangText(){Key="SubmitButtonLabel",Lcid=29,Value="Logga in"},
                new LangText(){Key="AuthenticationFailed",Lcid=29,Value=""},
                new LangText(){Key="ErrorInvalidSessionId",Lcid=29,Value="ErrorInvalidSessionId"},
                new LangText(){Key="ErrorInvalidContext",Lcid=29,Value="ErrorInvalidContext"},
                new LangText(){Key="ErrorNoUserIdentity",Lcid=29,Value="ErrorNoUserIdentity"},
                new LangText(){Key="ErrorNoAnswerProvided",Lcid=29,Value="ErrorNoAnswerProvided"},
                new LangText(){Key="ErrorFailSelected",Lcid=29,Value="ErrorFailSelected"},
                new LangText(){Key="ChoiceSuccess",Lcid=29,Value="ChoiceSuccess"},
                new LangText(){Key="ChoiceFail",Lcid=29,Value="ChoiceFail"},
                new LangText(){Key="UserChoice",Lcid=29,Value="UserChoice"},
                new LangText(){Key="FailedLogin",Lcid=29,Value="Ogiltigt lösenord, försök igen"}
            };
    }
}
