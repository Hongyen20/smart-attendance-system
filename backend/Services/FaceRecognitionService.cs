using Amazon.Rekognition;
using Amazon.Rekognition.Model;

namespace AttendanceApi.Services;

public class FaceRecognitionService
{
    private readonly IAmazonRekognition _rekognition;

    public FaceRecognitionService(
        IAmazonRekognition rekognition)
    {
        _rekognition = rekognition;
    }


    // COLLECTION

    // Tạo Face Collection cho một company. Mỗi company có một collection riêng.
    public async Task CreateCollectionAsync(
        string companyId)
    {
        var collectionId =
            GetCollectionId(companyId);

        try
        {
            await _rekognition.CreateCollectionAsync(
                new CreateCollectionRequest
                {
                    CollectionId = collectionId
                });
        }
        catch (ResourceAlreadyExistsException)
        {
            // Collection đã tồn tại.
        }
    }

    // Kiểm tra collection có tồn tại hay chưa.
    public async Task<bool> CollectionExistsAsync(
        string companyId)
    {
        var collectionId =
            GetCollectionId(companyId);

        try
        {
            await _rekognition.DescribeCollectionAsync(
                new DescribeCollectionRequest
                {
                    CollectionId = collectionId
                });

            return true;
        }
        catch (ResourceNotFoundException)
        {
            return false;
        }
    }


    // REGISTER FACE

    public async Task<string?> RegisterFaceAsync(
        string companyId,
        string userId,
        Stream imageStream)
    {
        var collectionId =
            GetCollectionId(companyId);

        // Đảm bảo collection tồn tại.
        await CreateCollectionAsync(companyId);

        using var memoryStream =
            new MemoryStream();

        await imageStream.CopyToAsync(
            memoryStream);

        var imageBytes =
            memoryStream.ToArray();

        if (imageBytes.Length == 0)
        {
            throw new ArgumentException(
                "Ảnh khuôn mặt không được để trống.");
        }

        try
        {
            var response =
                await _rekognition.IndexFacesAsync(
                    new IndexFacesRequest
                    {
                        CollectionId = collectionId,

                        Image = new Image
                        {
                            Bytes =
                                new MemoryStream(
                                    imageBytes)
                        },

                        ExternalImageId = userId,

                        MaxFaces = 1,

                        QualityFilter =
                            QualityFilter.AUTO,

                        DetectionAttributes =
                        [
                            Amazon.Rekognition.Attribute.DEFAULT
                        ]
                    });

            // Không có khuôn mặt hợp lệ.
            if (response.FaceRecords.Count == 0)
            {
                return null;
            }

            // Chỉ chấp nhận đúng một khuôn mặt.
            if (response.FaceRecords.Count != 1)
            {
                throw new InvalidOperationException(
                    "Ảnh phải chứa đúng một khuôn mặt.");
            }

            var faceRecord =
                response.FaceRecords[0];

            return faceRecord.Face?.FaceId;
        }
        catch (InvalidParameterException)
        {
            throw new InvalidOperationException(
                "Ảnh không hợp lệ hoặc không thể nhận diện khuôn mặt.");
        }
        catch (ImageTooLargeException)
        {
            throw new InvalidOperationException(
                "Ảnh quá lớn.");
        }
    }


    // VERIFY FACE


    // Xác thực khuôn mặt của nhân viên.

    public async Task<FaceVerificationResult>
        VerifyFaceAsync(
            string companyId,
            string userId,
            Stream imageStream)
    {
        var collectionId =
            GetCollectionId(companyId);

        if (!await CollectionExistsAsync(
                companyId))
        {
            return new FaceVerificationResult
            {
                Success = false,
                Message =
                    "Company chưa có Face Collection."
            };
        }

        using var memoryStream =
            new MemoryStream();

        await imageStream.CopyToAsync(
            memoryStream);

        var imageBytes =
            memoryStream.ToArray();

        if (imageBytes.Length == 0)
        {
            return new FaceVerificationResult
            {
                Success = false,
                Message =
                    "Ảnh khuôn mặt không được để trống."
            };
        }

        try
        {
            var response =
                await _rekognition.SearchFacesByImageAsync(
                    new SearchFacesByImageRequest
                    {
                        CollectionId =
                            collectionId,

                        Image = new Image
                        {
                            Bytes =
                                new MemoryStream(
                                    imageBytes)
                        },

                        // Ngưỡng nhận diện.
                        FaceMatchThreshold = 90f,

                        MaxFaces = 5
                    });

            foreach (var match
                     in response.FaceMatches)
            {
                var externalImageId =
                    match.Face.ExternalImageId;

                if (string.Equals(
                        externalImageId,
                        userId,
                        StringComparison.OrdinalIgnoreCase))
                {
                    return new FaceVerificationResult
                    {
                        Success = true,

                        Similarity =
                            match.Similarity,

                        FaceId =
                            match.Face.FaceId,

                        Message =
                            "Xác thực khuôn mặt thành công."
                    };
                }
            }

            return new FaceVerificationResult
            {
                Success = false,
                Message =
                    "Khuôn mặt không khớp với nhân viên hiện tại."
            };
        }
        catch (InvalidParameterException)
        {
            return new FaceVerificationResult
            {
                Success = false,
                Message =
                    "Không tìm thấy khuôn mặt hợp lệ trong ảnh."
            };
        }
        catch (ResourceNotFoundException)
        {
            return new FaceVerificationResult
            {
                Success = false,
                Message =
                    "Face Collection không tồn tại."
            };
        }
    }


    // DELETE FACE


    // Xóa khuôn mặt của nhân viên.

    public async Task DeleteFaceAsync(
        string companyId,
        string faceId)
    {
        var collectionId =
            GetCollectionId(companyId);

        await _rekognition.DeleteFacesAsync(
            new DeleteFacesRequest
            {
                CollectionId = collectionId,

                FaceIds =
                [
                    faceId
                ]
            });
    }


    // HELPER

    private static string GetCollectionId(
        string companyId)
    {
        return $"attendance-{companyId}";
    }
}


// FACE VERIFICATION RESULT
public class FaceVerificationResult
{
    public bool Success { get; set; }

    public float? Similarity { get; set; }

    public string? FaceId { get; set; }

    public string Message { get; set; } =
        string.Empty;
}
