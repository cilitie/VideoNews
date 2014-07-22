
#import <Foundation/Foundation.h>

//OSS Object操作类型
typedef enum {POST,GET,HEAD,PUT,DELETE} OSSMethod;
static NSString *OSSMethodLiterals[]={@"POST",@"GET",@"HEAD",@"PUT",@"DELETE"};

//OSS Bucket权限类型
typedef enum {PRIVATE,PRIVATE_W,PUBLIC} OSSBucketPermission;


@interface OSSMethodResult : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSDictionary *headers;

@end

@interface OSSClient : NSObject

/**
 * 初始化OSSClient
 * @bucket          要操作的bucket
 * @ossUrlBuilder   用于构造OSS URL的Blcok，用户请根据自身情况来构造URL，比如可在本地构造,也可以在服务端构造后传回给客户端，在构造URL的
 *                  时候，需要区分绑定域名和未绑定域名的情况
 * @signCalculator  OSS签名计算Block，为了不在客户端泄露KeySecret，强烈建议在服务端计算签名，然后在此Block从服务端请求签名
 *
 */
- (OSSClient *)initWithBucketBaseUrl:(NSURL *)bucketBaseUrl
                    bucketPermission:(OSSBucketPermission)bucketPermission
                      signCalculator:(NSString *(^)(OSSMethod method,NSString *ossFilePath,NSMutableDictionary *options)) signCalculator
                                Date:(NSString *)date;

/**
 * 上传文件
 *
 * @ossFilePath     OSS存储的文件路径
 * @localFilePath   要上传的本地文件
 * @options         支持Access-Control-Allow-Origin,Cache-Control,Content-Disposition,Content-Encoding,Expires,
 *                  x-oss-server-side-encryption
 */
- (OSSMethodResult *)putFile:(NSString *)ossFilePath
               localFilePath:(NSString *)localFilePath
                     options:(NSMutableDictionary *)options;

/**
 * 上传文件
 *
 * @ossFilePath     OSS存储的文件路径
 * @data            要保存的数据
 * @options         支持Access-Control-Allow-Origin,Cache-Control,Content-Disposition,Content-Encoding,Expires,
 *                  x-oss-server-side-encryption
 */
- (OSSMethodResult *)putFile:(NSString *)ossFilePath
                        data:(NSData *)data
                     options:(NSMutableDictionary *)options;

/**
 * 下载文件
 *
 * @ossFilePath     OSS存储的文件路径
 * @options         支持If-Modified-Since,If-Unmodified-Since,If-Match,If-None-Match,Range
 */
- (OSSMethodResult *)getFile:(NSString *)ossFilePath
                     options:(NSMutableDictionary *)options;

/**
 * 删除文件
 *
 * @ossFilePath     OSS存储的文件路径
 */
- (OSSMethodResult *)deleteFile:(NSString *)ossFilePath;

/**
 * 对OSS存储的文件进行HTTP HEAD操作
 *
 * @ossFilePath     OSS存储的文件路径
 * @options         支持If-Modified-Since,If-Unmodified-Since,If-Match,If-None-Match
 */
- (OSSMethodResult *)headFile:(NSString *)ossFilePath
                      options:(NSMutableDictionary *)options;

@end
