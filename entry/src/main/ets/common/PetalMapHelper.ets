import { petalMaps, mapCommon } from '@kit.MapKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface PetalMapResult {
  success: boolean;
  unavailable: boolean;
  message: string;
}

/**
 * 花瓣地图零鉴权导航与 POI 跳转助手（@kit.MapKit petalMaps）
 * - 校内接口沿用高德 GCJ-02 坐标系，与 petalMaps 默认 CoordinateType.GCJ02 一致
 * - 自动映射 SchoolMapPage routeMode (0=驾车, 2=步行, 3=骑行) -> petalMaps.VehicleType (0, 1, 2)
 */
export class PetalMapHelper {
  /** 纯函数：校验并解析经纬度坐标对 */
  public static parseCoordinatePair(latRaw: string, lonRaw: string): mapCommon.LatLng | null {
    const latStr: string = (latRaw || '').trim();
    const lonStr: string = (lonRaw || '').trim();
    if (latStr === '' || lonStr === '') {
      return null;
    }
    const lat: number = Number(latStr);
    const lon: number = Number(lonStr);
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
      return null;
    }
    if (lat === 0 && lon === 0) {
      return null;
    }
    if (lat < -85.2 || lat > 85.2 || lon < -180 || lon >= 180) {
      return null;
    }
    return {
      latitude: lat,
      longitude: lon
    };
  }

  /** 纯函数：映射页面出行方式（0=驾车, 2=步行, 3=骑行）至 petalMaps.VehicleType */
  public static mapRouteModeToVehicleType(routeMode: number): petalMaps.VehicleType {
    if (routeMode === 0) {
      return petalMaps.VehicleType.DRIVING;
    }
    if (routeMode === 3) {
      return petalMaps.VehicleType.CYCLING;
    }
    if (routeMode === 2) {
      return petalMaps.VehicleType.WALKING;
    }
    return petalMaps.VehicleType.WALKING;
  }

  /** 纯函数：构建花瓣地图路线规划参数（GCJ-02） */
  public static buildRoutePlanParams(
    latRaw: string,
    lonRaw: string,
    destName: string,
    routeMode: number
  ): petalMaps.RoutePlanParams | null {
    const coords: mapCommon.LatLng | null = PetalMapHelper.parseCoordinatePair(latRaw, lonRaw);
    if (coords === null) {
      return null;
    }
    const cleanName: string = (destName || '').trim();
    return {
      destinationPosition: coords,
      destinationName: cleanName !== '' ? cleanName : '目的地',
      vehicleType: PetalMapHelper.mapRouteModeToVehicleType(routeMode),
      coordinateType: mapCommon.CoordinateType.GCJ02
    };
  }

  /** 纯函数：构建花瓣地图 POI 详情参数（GCJ-02） */
  public static buildPoiDetailParams(
    latRaw: string,
    lonRaw: string,
    destName: string,
    address?: string
  ): petalMaps.PoiDetailParams | null {
    const coords: mapCommon.LatLng | null = PetalMapHelper.parseCoordinatePair(latRaw, lonRaw);
    if (coords === null) {
      return null;
    }
    const cleanName: string = (destName || '').trim();
    const cleanAddr: string = (address || '').trim();
    const params: petalMaps.PoiDetailParams = {
      destinationPosition: coords,
      destinationName: cleanName !== '' ? cleanName : '位置详情',
      zoom: 17,
      coordinateType: mapCommon.CoordinateType.GCJ02
    };
    if (cleanAddr !== '') {
      params.destinationAddress = cleanAddr;
    }
    return params;
  }

  /** 纯函数：映射 MapKit 错误码为结构化结果 */
  public static formatMapError(code: number): PetalMapResult {
    if (code === 1002600014) {
      return {
        success: false,
        unavailable: true,
        message: '未安装花瓣地图或无法拉起导航'
      };
    }
    if (code === 801) {
      return {
        success: false,
        unavailable: true,
        message: '当前设备暂不支持地图导航跳转'
      };
    }
    if (code === 401) {
      return {
        success: false,
        unavailable: false,
        message: '地点坐标格式无效'
      };
    }
    return {
      success: false,
      unavailable: true,
      message: '拉起地图失败，请稍后重试'
    };
  }

  /** 调起花瓣地图路线规划 */
  public static async openRoutePlan(
    context: common.Context,
    latRaw: string,
    lonRaw: string,
    destName: string,
    routeMode: number
  ): Promise<PetalMapResult> {
    if (!context) {
      return {
        success: false,
        unavailable: true,
        message: '缺少应用上下文'
      };
    }
    const params: petalMaps.RoutePlanParams | null = PetalMapHelper.buildRoutePlanParams(
      latRaw,
      lonRaw,
      destName,
      routeMode
    );
    if (params === null) {
      return {
        success: false,
        unavailable: false,
        message: '地点坐标无效'
      };
    }
    try {
      await petalMaps.openMapRoutePlan(context, params);
      return {
        success: true,
        unavailable: false,
        message: ''
      };
    } catch (err) {
      const be = err as BusinessError;
      return PetalMapHelper.formatMapError(be.code ?? -1);
    }
  }

  /** 调起花瓣地图 POI 详情 */
  public static async openPoiDetail(
    context: common.Context,
    latRaw: string,
    lonRaw: string,
    destName: string,
    address?: string
  ): Promise<PetalMapResult> {
    if (!context) {
      return {
        success: false,
        unavailable: true,
        message: '缺少应用上下文'
      };
    }
    const params: petalMaps.PoiDetailParams | null = PetalMapHelper.buildPoiDetailParams(
      latRaw,
      lonRaw,
      destName,
      address
    );
    if (params === null) {
      return {
        success: false,
        unavailable: false,
        message: '地点坐标无效'
      };
    }
    try {
      await petalMaps.openMapPoiDetail(context, params);
      return {
        success: true,
        unavailable: false,
        message: ''
      };
    } catch (err) {
      const be = err as BusinessError;
      return PetalMapHelper.formatMapError(be.code ?? -1);
    }
  }
}
