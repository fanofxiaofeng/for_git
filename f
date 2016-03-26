package com.dianping.credit.refundoperation.impl;

import com.dianping.credit.refundoperation.service.CreditRefundOperation;
import com.dianping.credit.refundoperation.service.CreditRefundResponse;
import com.dianping.pay.common.enums.PayPlatform;
import com.dianping.pay.common.enums.ProductCode;
import com.dianping.refund.platform.api.model.RefundApplyRequestDTO;
import com.dianping.refund.platform.api.model.RefundResponse;
import com.dianping.refund.platform.api.model.enums.OperatorType;
import com.dianping.refund.platform.api.model.enums.RefundDestination;
import com.dianping.refund.platform.api.model.enums.RefundProcessTemplate;
import com.dianping.refund.platform.api.service.RefundApplyRemoteService;
import com.dianping.takeaway.base.honesty.entity.RefundResult;
import com.dianping.takeaway.base.honesty.service.TakeawayHonestyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 处理 团购退款 和 外卖退款
 */
public class CreditRefundOperationImpl implements CreditRefundOperation {
    /**
     * 记录日志
     */
    private Logger logger = LoggerFactory.getLogger(CreditRefundOperationImpl.class);

    private TakeawayHonestyService takeawayHonestyService;
    private RefundApplyRemoteService refundApplyRemoteService;

    /**
     * 对数据库的表进行操作
     */
    private JdbcTemplate jdbcTemplate;

    /**
     * 在数据库中记录相关信息 (与记录日志的效果类似)
     */
    private LogJob logJob;

    /**
     * 处理 团购退款 和 外卖退款
     *
     * @param orderID          如字面含义
     * @param productCodeValue 用于指定具体类型(比如团购)
     * @param operatorType     T+1 指离线, T+0 指实时
     * @param refundReason     退款原因
     * @return 处理退款的结果
     */
    @Override
    public CreditRefundResponse refundAnyOrder(int orderID, int productCodeValue, int operatorType, String refundReason) {
        CreditRefundResponse response = new CreditRefundResponse();

        String msg = "No according punish method";
        if (productCodeValue == ProductCode.TUANGOU.getCode()) {
            msg = refundTuanGouOrder(orderID, productCodeValue, operatorType, refundReason);
        } else if (productCodeValue == ProductCode.TAKEAWAY.getCode() ||
                productCodeValue == ProductCode.TAKEAWAYPOS.getCode()) {
            msg = refundTakeawayOrder(orderID, productCodeValue, operatorType, refundReason);
        }

        response.setSuccess(msg.equals("success"));
        response.setMsg(msg);

        return response;
    }

    /**
     * 处理 外卖退款
     *
     * @param orderID          如字面含义
     * @param productCodeValue 如字面含义
     * @param operatorType     T+1 指离线, T+0 指实时
     * @param refundReason     退款原因
     * @return 处理结果
     */
    private String refundTakeawayOrder(int orderID, int productCodeValue, int operatorType, String refundReason) {
        String msg = "success";
        try {
            List<Integer> refundOidList = new ArrayList<Integer>();
            refundOidList.add(orderID);
            List<RefundResult> refundResultList = takeawayHonestyService.refundBacktrackingOrders(refundOidList);
            for (RefundResult result : refundResultList)
                if (result.isSuccess()) {
                    int rowCnt = logJob.recordRefund(orderID, productCodeValue, 1, operatorType, 1, refundReason);
                    logger.info(String.format("外卖退款成功: %d, rowCnt: %d", orderID, rowCnt));
                } else {
                    msg = result.getFailMsg();
                    int rowCnt = logJob.updateRefundRecord(orderID, productCodeValue, -1, operatorType, refundReason);
                    logger.error(String.format("外卖退款失败: %d, FailType: %d, rowCnt: %d", orderID, result.getFailedType(), rowCnt));
                }
        } catch (Exception e) {
            logger.error("myExp: ", e);
        }

        return msg;
    }

    /**
     * 处理 团购退款
     *
     * @param orderID          对应数据库中的 oid
     * @param productCodeValue 如字面含义
     * @param operatorType     T+1 指离线, T+0 指实时
     * @param refundReason     退款原因
     * @return 处理结果
     */
    private String refundTuanGouOrder(int orderID, int productCodeValue, int operatorType, String refundReason) {
        String msg = "success";

        final ArrayList<Integer> orderInfo = new ArrayList<Integer>();

        // 如果查询成功, 应该恰有1条记录命中
        // orderInfo 的 size 应该恰为 5
        jdbcTemplate.query(
                "SELECT distinct oid, quantity, userid, productid, productgid " +
                        "FROM credit_mfchwl_order_detail " +
                        "WHERE oid IN (" + orderID + ") and productCodeValue = 1",
                new org.springframework.jdbc.core.RowMapper() {
                    public Object mapRow(ResultSet rs, int rowNum) throws SQLException {
                        orderInfo.add(rs.getInt(1));
                        orderInfo.add(rs.getInt(2));
                        orderInfo.add(rs.getInt(3));
                        orderInfo.add(rs.getInt(4));
                        orderInfo.add(rs.getInt(5));
                        return null;
                    }
                });

        if (orderInfo.size() < 5) {
            msg = "no such order: " + orderID + ", productCodeValue: " + productCodeValue;
            return msg;
        }

        int quantity = orderInfo.get(1);
        int userid = orderInfo.get(2);
        int productid = orderInfo.get(3);
        int productgid = orderInfo.get(4);

        RefundApplyRequestDTO dto = new RefundApplyRequestDTO();
        dto.setOrderID(orderID);
        dto.setProductCode(ProductCode.TUANGOU);
        dto.setRefundQuantity(quantity);
        dto.setUserID(userid);
        dto.setProductID(productid);
        dto.setProductGroupID(productgid);
        dto.setOperatorType(OperatorType.CREDIT);
        dto.setRefundDestination(RefundDestination.SOURCE);
        dto.setRefundPlatform(PayPlatform.ht_pc);
        dto.setRefundReason("诚信退款");
        dto.setRefundTemplateID(RefundProcessTemplate.TUANGOU_CREDIT_REFUND.getTemplateID());

        logger.info("RefundIDs: " + orderInfo);

        // 提交退款申请
        RefundResponse refundResponse = refundApplyRemoteService.submitRefundApplyRequest(dto);

        // 在 日志 和 数据库 中记录处理结果
        if (refundResponse.isSuccess()) {
            logger.info("Refund Success: " + orderID);
            logJob.recordRefund(orderID, productCodeValue, 1, operatorType, quantity, refundReason);
        } else if (refundResponse.getResultMsg().contains("订单未支付成功")) {
            msg = refundResponse.getResultMsg();
            logger.info("unpaid: " + orderID);
            logJob.recordRefund(orderID, productCodeValue, 1, operatorType, quantity, refundReason);
        } else {
            msg = refundResponse.getResultMsg();
            logger.info("Refund Failed: " + orderID);
            logJob.recordRefund(orderID, productCodeValue, -1, operatorType, quantity, refundResponse.getResultMsg());
        }

        return msg;
    }

    public void setTakeawayHonestyService(TakeawayHonestyService takeawayHonestyService) {
        this.takeawayHonestyService = takeawayHonestyService;
    }

    public void setJdbcTemplate(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void setRefundApplyRemoteService(RefundApplyRemoteService refundApplyRemoteService) {
        this.refundApplyRemoteService = refundApplyRemoteService;
    }

    public void setLogJob(LogJob logJob) {
        this.logJob = logJob;
    }
}
