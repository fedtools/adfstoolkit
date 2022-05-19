
namespace ADFSTK.ExternalMFA
{
    internal static class Constants
    {
        public const string RefedsMFA = "https://refeds.org/profile/mfa";

        public const string AuthenticationMethodClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod";
        public const string WindowsAccountNameClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname";
        public const string UpnClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn";

        public static class AuthContextKeys
        {
            public const string SessionId = "sessionid";
            public const string Identity = "id";
            public const string Token = "eduidtoken";
            
        }

        public static class DynamicContentLabels
        {
            public const string markerUserName = "%LoginPageUserName%";
            public const string markerOverallError = "%PageErrorOverall%";
            public const string markerActionUrl = "%PageActionUrl%";
            public const string markerPageIntroductionTitle = "%PageIntroductionTitle%";
            public const string markerPageIntroductionText = "%PageIntroductionText%";
            public const string markerPageTitle = "%PageTitle%";
            public const string markerSubmitButton = "%PageSubmitButtonLabel%";
            public const string markerChoiceSuccess = "%ChoiceSuccess%";
            public const string markerChoiceFail = "%ChoiceFail%";
            public const string markerUserChoice = "%UserChoice%";
            public const string markerLoginPageUsername = "%Username%";
            public const string markerLoginExternalTabUrl = "%ExternalMFAUrl%";
            public const string markerView = "%View%";
            public const string markerPageTabInfoText = "%TabInfoText%";
            public const string markerPageTrustedUrl ="%TrustedUrl%";

        }

        public static class ResourceNames
        {
            public const string AdminFriendlyName = "AdminFriendlyName";
            public const string Description = "Description";
            public const string PageIntroductionTitle = "PageIntroductionTitle";
            public const string PageIntroductionText = "PageIntroductionText";
            public const string AuthPageTab = "LoginExternalTabHtml";
            public const string AuthPageError = "LoginErrorHtml";
            public const string PageTitle = "PageTitle";
            public const string SubmitButtonLabel = "SubmitButtonLabel";
            public const string FinishButtonLabel = "FinishButtonLabel";
            public const string AuthenticationFailed = "AuthenticationFailed";
            public const string ErrorInvalidSessionId = "ErrorInvalidSessionId";
            public const string ErrorInvalidContext = "ErrorInvalidContext";
            public const string ErrorNoUserIdentity = "ErrorNoUserIdentity";
            public const string ErrorNoAnswerProvided = "ErrorNoAnswerProvided";
            public const string ErrorFailSelected = "ErrorFailSelected";
            public const string ChoiceSuccess = "ChoiceSuccess";
            public const string ChoiceFail = "ChoiceFail";
            public const string UserChoice = "UserChoice";
            public const string FailedLogin = "FailedLogin";
            public const string ViewStart = "ViewStart";
            public const string TabInfoText = "TabInfoText";
        }

        public static class PropertyNames
        {
            public const string UserSelection = "UserSelection";
            public const string AuthenticationMethod = "AuthMethod";
            public const string Password = "PasswordInput";
            public const string Username = "Username";
            public const string View = "View";
        }

        public static class Lcid
        {
            public const int En = 0x9;   
            public const int Sv = 0x1D;      
        }
    }
}
