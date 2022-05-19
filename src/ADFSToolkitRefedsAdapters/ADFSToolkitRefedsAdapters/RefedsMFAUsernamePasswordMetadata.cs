//------------------------------------------------------------
// Copyright (c) Microsoft Corporation.  All rights reserved.
//------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using Microsoft.IdentityServer.Web.Authentication.External;
using System.Collections.Generic;
using System.Globalization;

namespace ADFSTk
{
    public class RefedsMFAUsernamePasswordMetadata : IAuthenticationAdapterMetadata
    {
        protected string GetMetadataResource(string resourceName, int lcid)
        {
            return ResourceHandler.GetResource(resourceName, lcid);
        }

        private readonly Dictionary<int, string> _descriptions = new Dictionary<int, string>();
        private readonly Dictionary<int, string> _friendlyNames = new Dictionary<int, string>();

        private readonly int[] _supportedLcids = new[] { Constants.Lcid.En, Constants.Lcid.Sv };

        public RefedsMFAUsernamePasswordMetadata()
        {
            for (int index = 0; index < _supportedLcids.Length; index++)
            {
                int lcid = _supportedLcids[index];
                _descriptions.Add(lcid, GetMetadataResource(Constants.ResourceNames.Description, lcid));
                _friendlyNames.Add(lcid, GetMetadataResource(Constants.ResourceNames.FriendlyName, lcid));
            }
        }

        #region IAuthenticationHandlerMetadata Members

        public string AdminName
        {
            get { return Constants.ResourceNames.AdminFriendlyNameMFA; }
        }

        public virtual string[] AuthenticationMethods
        {
            get { return new[] { Constants.RefedsMFAUsernamePassword }; }
        }

        public Dictionary<int, string> Descriptions
        {
            get { return _descriptions; }
        }

        public Dictionary<int, string> FriendlyNames
        {
            get { return _friendlyNames; }
        }

        public string[] IdentityClaims
        {
            get { return new[] { Constants.UpnClaimType }; }
        }

        public bool RequiresIdentity
        {
            get { return true; }
        }

        public int[] AvailableLcids
        {
            get { return _supportedLcids; }
        }

        #endregion
    }
}
