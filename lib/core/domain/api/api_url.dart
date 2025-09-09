// const serverUrl = kDebugMode ? "http://192.168.0.253:28008" : 'http://14.36.141.253:28008';
// const serverUrl = 'http://49.247.6.165:28008';
const serverUrl =
    'http://192.168.0.120:28008';
    //  'http://t-pass.co.kr:28008';


const profileUrl = '$serverUrl/url';

const authUrl = '$serverUrl/auth';
const checkCodeUrl = '$serverUrl/auth/code';
const signupUrl = '$serverUrl/auth/register';
const loginUrl = '$serverUrl/auth/sign-in';
const enterpriseUrl = '$serverUrl/enterprise';
const checkAuthUrl = '$serverUrl/auth/check';
const visitorUrl = '$serverUrl/visitor';
const resourceUrl = '$serverUrl/resource/files?fileName=';
const historyUrl = '$serverUrl/history';
const locationEnableUrl = '$serverUrl/location/enable';
const deviceUrl = '$serverUrl/device';
const subAdminUrl = '$serverUrl/enterprise/sub';
const subAdminAddUrl = '$signupUrl/enterprise/sub';
const subAdminPatchUrl = '$serverUrl/enterprise/auth/sub';

const addressUrl = 'https://dapi.kakao.com/v2/local/search/address.json';
