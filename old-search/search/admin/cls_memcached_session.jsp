<%@ page pageEncoding="UTF-8" %>
<%@ page contentType="text/html; charset=UTF-8" language="java"%>
<%@ page import="com.danga.MemCached.MemCachedClient"%>
<%@ page import="com.danga.MemCached.SockIOPool"%>
<%@ page import="java.util.*"%>
<%@ page import="java.util.regex.Matcher"%>
<%@ page import="java.util.regex.Pattern"%>
<%!

/**
 * 基于共享Memcached的Session类
 */
public class MemcachedSession
{
    private HttpSession m_session;
    private HttpServletRequest m_request;
    private HttpServletResponse m_response;
    private JspWriter m_out;
    private String m_sessionId;
    private Map<String, String> m_sessionInfo;

    /**
     * 构造函数
     */
    public MemcachedSession(HttpSession session,
                            HttpServletRequest request,
                            HttpServletResponse response,
                            JspWriter out,
                            Boolean updateSessionId)
    {
        try{
            m_session     = session;
            m_request     = request;
            m_response    = response;
            m_out         = out;
            m_sessionId   = "";
            m_sessionInfo = new HashMap<String, String>();

            if(updateSessionId){
                m_sessionId = (String) request.getParameter("code");            //从远程主机获得SessionId
                m_session.setAttribute("remoteSessionId", m_sessionId);
            }else{
                m_sessionId = (String) session.getAttribute("remoteSessionId"); //在本机获取SessionId
            }
            //synchronSession();
        }catch(Exception ex){
            System.out.println(ex);
        }
    }

    /**
     * 取得Session Id
     */
    public String getId(){
        return m_sessionId;
    }

    /**
     * 设置Session字段值
     */
    public void set(String key, String value)
    {
        this.m_sessionInfo.put(key, value);
        //向远程主机传递Session信息
    }

    /**
     * 取得Session字段值
     */
    public String get(String key)
    {
        String value = "";
        //在每次取值前先同步Session
        synchronSession();
        if(m_sessionInfo != null){
            value = (String) m_sessionInfo.get(key);
        }
        return value;
    }

    /**
     * 判断会员和管理员是否登录
     */
     public Boolean isLogin(String userType){
        if(userType != null && !userType.equals("")){
            String username = "";
            if(userType.equals("member")){
                username = (String) this.get("username");
            }else if(userType.equals("admin")){
                username = (String) this.get("adminName");
            }
            if(username != null && !username.equals("")){
                return true;
            }
        }
        return false;
     }

    /**
     * 判断管理员是否具有某个权限
     */
    public Boolean hasPermission(String flag){
        String contents = (String) this.get("adminAllowOperation");
        if(flag != null && !flag.equals("") && contents != null && !contents.equals("")){
            if(contents.indexOf(flag) > -1){
                return true;
            }
        }
        return false;
    }

    public Boolean hasPermission(String[] flags){
        int count = 0;
        String contents = (String) this.get("adminAllowOperation");
        if(flags != null && flags.length > 0 && contents != null && !contents.equals("")){
            for(int i=0; i < flags.length; i++){
                String flag = flags[i];
                if(flag != null && !flag.equals("") ){
                    if(contents.indexOf(flag) == -1){
                        return false;
                    }else{
                        count ++;
                    }
                }
            }
        }
        return (count == flags.length);
    }

    /**
     * 同步远程服务器Session
     */
    private void synchronSession(){
        String data = getSessionData();
        if(data != null && !data.equals("")){
            m_sessionInfo = AnalyzeSession(data);
            //同步JSP的Session
            /*if(m_sessionInfo != null){
                for(String key : m_sessionInfo.keySet()){
                    String value = (String) m_sessionInfo.get(key);
                    //m_session.setAttribute(key, value);
                }
            }*/
        }
    }

    /**
     * 将Session字符串转为Map
     */
    private Map<String, String> AnalyzeSession(String sessionInfo){
        Map<String, String> sessionMap = new HashMap<String, String>();
        String key = "", value = "";
        String[] contents = sessionInfo.split(";");
        for(String line : contents){
            String[] parts = line.split("\\|");
            if(parts.length == 2){
                key = parts[0];
                if(parts[1].matches("[a-z]*:[0-9]*:\".*\"")){
                    Pattern pattern = Pattern.compile("([a-z]*):([0-9]*):\"(.*)\"", Pattern.CASE_INSENSITIVE);
                    Matcher matcher = pattern.matcher(parts[1]);
                    if(matcher.find()){ value = matcher.group(3); }
                }
            }
            if(!key.equals("")){ sessionMap.put(key, value); }
        }
        return sessionMap;
    }

    /**
     * 根据Session Id取得存储在Memcached中的Session信息
     */
    private String getSessionData(){
        String sessionInfo = "";
        try{
            //DOMConfigurator.configure("c:/log4j.xml");//加载.xml文件 
            //Logger log = Logger.getLogger("com.kongfz.pay.test");
            //System.setProperty( "org.apache.commons.logging.Log", "org.apache.commons.logging.impl.NoOpLog");

            //创建一个实例对象SockIOPool
            String[] servers ={"192.168.1.151:21219"}; //192.168.1.75:21212
            SockIOPool pool = SockIOPool.getInstance();
            pool.setServers(servers);
            pool.setFailover(true);
            pool.setInitConn(10);
            pool.setMinConn(5);
            pool.setMaxConn(250);
            pool.setMaintSleep(30);
            pool.setNagle(false);
            pool.setSocketTO(3000);
            pool.setAliveCheck(true);
            pool.initialize();

            MemCachedClient mcc = new MemCachedClient(); 
            mcc.setCompressEnable(true);
            mcc.setCompressThreshold(64 * 1024);
            mcc.setPrimitiveAsString(true);
            
            //从Memcached中的取得Session信息
            sessionInfo = (String) mcc.get(m_sessionId); 
        }catch(Exception ex){}
        return sessionInfo;
    }

} // end class


%>