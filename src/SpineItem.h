#pragma once

#include <QQuickItem>
#include <QString>
#include <QElapsedTimer>
#include <QtQml/qqmlregistration.h>
#include <QMap>
#include <QSGTexture>
#include <QPointF>
#include <spine/spine.h>

class SpineItem : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString skelSource READ skelSource WRITE setSkelSource NOTIFY sourceChanged)
    Q_PROPERTY(QString atlasSource READ atlasSource WRITE setAtlasSource NOTIFY sourceChanged)
    Q_PROPERTY(QString animation READ animation WRITE setAnimation NOTIFY animationChanged)

public:
    explicit SpineItem(QQuickItem *parent = nullptr);
    ~SpineItem() override;

    QString skelSource() const { return m_skelSource; }
    void setSkelSource(const QString &source);

    QString atlasSource() const { return m_atlasSource; }
    void setAtlasSource(const QString &source);

    QString animation() const { return m_animation; }
    void setAnimation(const QString &animationName);

    Q_INVOKABLE void setTrackAnimation(int track, const QString &animationName, bool loop);
    Q_INVOKABLE void addTrackAnimation(int track, const QString &animationName, bool loop, float delay);
    Q_INVOKABLE void clearTrack(int track);

    // New Bone Manipulation Bridge
    Q_INVOKABLE QPointF getBonePosition(const QString &boneName);
    Q_INVOKABLE void setBonePosition(const QString &boneName, float x, float y);
    Q_INVOKABLE void clearBonePosition(const QString &boneName);

    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data) override;

Q_SIGNALS:
    void sourceChanged();
    void animationChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

private Q_SLOTS:
    void updateAnimation();

private:
    void loadSkeleton();

    QString m_skelSource;
    QString m_atlasSource;
    QString m_animation;

    spine::Atlas* m_atlas = nullptr;
    spine::SkeletonData* m_skeletonData = nullptr;
    spine::Skeleton* m_skeleton = nullptr;
    spine::AnimationStateData* m_animationStateData = nullptr;
    spine::AnimationState* m_animationState = nullptr;

    QElapsedTimer m_timer;
    class QtTextureLoader* m_textureLoader = nullptr;
    
    QMap<void*, QSGTexture*> m_textures;
    QMap<QString, QPointF> m_overriddenBones;
};